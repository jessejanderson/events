defmodule Events.Event do
  @moduledoc false

  alias Events.{Conflict, EventList, Helpers, Room}
  alias Calendar.DateTime.Interval
  alias Calendar.DateTime, as: CalDT

  use GenServer

  @enforce_keys [:name]
  defstruct [
    description: nil,
    id: nil,
    interval: %Calendar.DateTime.Interval{},
    name: nil,
    rooms: [],
    recurrence: nil,
  ]

  # TODO: get dynamic tz from org or local
  @timezone "Etc/UTC"

  # +-------+
  # | A P I |
  # +-------+

  # TODO: generate event_id automatically
  def new(org_id, event_id, name) do
    EventList.start_event(org_id, event_id, name)
  end

  def start_link(org_id, event_id, event_name) do
    name = via_tuple(org_id, event_id)
    GenServer.start_link(__MODULE__, {event_id, event_name}, name: name)
  end

  def stop(event, reason \\ :normal, timeout \\ :infinity) do
    # reason can be {:shutdown, erl_term} to save state on death
    GenServer.stop(event, reason, timeout)
  end

  def description(event), do: GenServer.call(event, :description)
  def interval(event),    do: GenServer.call(event, :interval)
  def name(event),        do: GenServer.call(event, :name)
  def rooms(event),       do: GenServer.call(event, :rooms)
  def recurrence(event),  do: GenServer.call(event, :recurrence)

  def occurrences(event, %CalDT.Interval{} = interval) when is_pid(event) do
    GenServer.call(event, {:occurrences, interval})
  end

  def next_occurrence(event) when is_pid(event) do
    GenServer.call(event, :next_occurrence)
  end

  def set_description(event, description) when is_pid(event) do
    GenServer.call(event, {:set_description, description})
  end

  def set_interval(event,
    {{_, _, _}, {_, _, _}} = start_erl,
    {{_, _, _}, {_, _, _}} = end_erl
  ) when is_pid(event) do
    GenServer.call(event, {:set_interval, start_erl, end_erl})
  end

  def set_name(event, name) when is_pid(event) do
    GenServer.call(event, {:set_name, name})
  end

  def set_recurrence(event, rules) when is_pid(event) do
    GenServer.call(event, {:set_recurrence, rules})
  end

  def add_room(event, room) when is_pid(room) when is_pid(event) do
    GenServer.call(event, {:add_room, room})
  end

  def remove_room(event, room) when is_pid(room) when is_pid(event) do
    GenServer.call(event, {:remove_room, room})
  end

  # def conflict?(event, %CalDT.Interval{} = interval) when is_pid(event) do
  #   GenServer.call(event, {:conflict, interval})
  # end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init({id, name}) do
    {:ok, %__MODULE__{id: id, name: name}}
  end

  def terminate(reason, state) do
    IO.puts "!!!!! Killing Event process: \"#{state.name}\", #{inspect self()}"
    IO.puts "! ! ! Reason: #{reason}"
  end

  def handle_call(:description, _from, st), do: {:reply, st.description, st}
  def handle_call(:interval, _from, st),    do: {:reply, st.interval, st}
  def handle_call(:name, _from, st),        do: {:reply, st.name, st}
  def handle_call(:rooms, _from, st),       do: {:reply, st.rooms, st}
  def handle_call(:recurrence, _from, st),  do: {:reply, st.recurrence, st}

  def handle_call({:occurrences, interval}, _from, state) do
    occurrences = do_occurrences(state, interval)
    {:reply, {:ok, occurrences}, state}
  end

  def handle_call(:next_occurrence, _from, state) do
    datetime = do_next_occurrence(state.interval.from, state.recurrence)
    {:reply, {:ok, datetime}, state}
  end

  def handle_call({:set_description, description}, _from, state) do
    new_state = %__MODULE__{state | description: description}
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:set_name, name}, _from, state) do
    new_state = %__MODULE__{state | name: name}
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:set_interval, start_erl, end_erl}, _from, state) do
    new_state = do_set_interval(state, start_erl, end_erl, @timezone)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:set_recurrence, rules}, _from, state) do
    new_state = do_set_recurrence(state, rules)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:add_room, room}, _from, state) do
    new_state = do_add_room(state, room)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:remove_room, room}, _from, state) do
    new_state = do_remove_room(state, room)
    {:reply, {:ok, new_state}, new_state}
  end

  # def handle_call({:conflict, interval}, _from, state) do
  #   conflict = do_conflict(state, interval)
  #   {:reply, {:ok, conflict}, state}
  # end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  defp do_occurrences(state, interval) do
    state.interval.from
    |> RecurringEvents.unfold(state.recurrence)
    |> Stream.filter(&(same_or_after?(&1, interval.from)))
    |> Enum.take_while(&(same_or_before?(&1, interval.to)))
  end

  defp same_or_after?(%DateTime{} = dt1, %DateTime{} = dt2) do
    CalDT.after?(dt1, dt2) || CalDT.same_time?(dt1, dt2)
  end

  defp same_or_before?(%DateTime{} = dt1, %DateTime{} = dt2) do
    CalDT.before?(dt1, dt2) || CalDT.same_time?(dt1, dt2)
  end

  def do_next_occurrence(from_date, rules) do
    from_date
    |> RecurringEvents.unfold(rules)
    |> Enum.find(fn(date) ->
      CalDT.after?(date, CalDT.now!(@timezone))
    end)
  rescue
    msg in ArgumentError -> msg
  end

  defp do_set_interval(state, start_erl, end_erl, timezone) do
    interval = Events.DateTime.create_interval(start_erl, end_erl, timezone)
    %__MODULE__{state | interval: interval}
  end

  def do_set_recurrence(state, rules) when is_list(rules) do
    rules = rules |> Enum.into(%{})
    do_set_recurrence(state, rules)
  end

  def do_set_recurrence(state, rules) do
    %__MODULE__{state | recurrence: rules}
  end

  defp do_add_room(state, room) do
    conflicts =
      room
      |> Conflict.check_room_for_conflicts(state.interval, state.recurrence)
      |> Conflict.create_conflicts(self())

    Room.add_conflicts(room, conflicts)

    {:ok, rooms} = Helpers.add_pid_if_unique(state.rooms, room)
    Room.add_event(room, self(), state.interval)
    %__MODULE__{state | rooms: rooms}
  end

  defp do_remove_room(state, room) do
    rooms = List.delete(state.rooms, room)
    {:ok, _} = Room.remove_event(room, self())
    %__MODULE__{state | rooms: rooms}
  end

  # defp do_conflict(state, interval) do
  #   [state.interval.from, state.interval.to]
  #   |> Enum.any?(&(Interval.includes?(interval, &1)))
  # end

  defp via_tuple(org_id, event_id) do
    {:via, Registry, {:process_registry, {:event, org_id, event_id}}}
  end

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(event), do: GenServer.call(event, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
