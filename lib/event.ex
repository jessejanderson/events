defmodule Events.Event do
  @moduledoc false

  alias Events.{Conflict, Event, EventList, Helpers, Room, RoomList}
  alias Events.Event.Schedule
  alias Calendar.DateTime.Interval
  alias Calendar.DateTime, as: CalDT

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :description,
    :name,
    interval: %Calendar.DateTime.Interval{},
    rooms: [],
    schedule: %Schedule{},
  ]

  # TODO: get dynamic tz from org or local
  @timezone "America/Los_Angeles"

  # +-------+
  # | A P I |
  # +-------+

  def new(name) do
    EventList.start_event(name)
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def stop(room, reason \\ :normal, timeout \\ :infinity) do
    # reason can be {:shutdown, erl_term} to save state on death
    GenServer.stop(room, reason, timeout)
  end

  def description(event), do: GenServer.call(event, :description)
  def interval(event),    do: GenServer.call(event, :interval)
  def name(event),        do: GenServer.call(event, :name)
  def rooms(event),       do: GenServer.call(event, :rooms)
  def schedule(event),    do: GenServer.call(event, :schedule)

  def occurrences(event, %CalDT.Interval{} = interval) do
    GenServer.call(event, {:occurrences, interval})
  end

  def next_occurrence(event) do
    GenServer.call(event, :next_occurrence)
  end

  def set_description(event, description) do
    GenServer.call(event, {:set_description, description})
  end

  def set_interval(event, start_erl, end_erl) do
    GenServer.call(event, {:set_interval, start_erl, end_erl})
  end

  def set_name(event, name) do
    GenServer.call(event, {:set_name, name})
  end

  def set_schedule(event, %Schedule{} = schedule) do
    GenServer.call(event, {:set_schedule, schedule})
  end

  def add_room(event, room) when is_pid(room) do
    GenServer.call(event, {:add_room, room})
  end

  def remove_room(event, room) when is_pid(room) do
    GenServer.call(event, {:remove_room, room})
  end

  def conflict?(event, %CalDT.Interval{} = interval) do
    GenServer.call(event, {:conflict, interval})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
    {:ok, %__MODULE__{name: name}}
  end

  def terminate(reason, state) do
    # IO.puts "!!!!! Killing Event process: \"#{state.name}\", #{inspect self()}"
    # EventsList.remove_event(self())
    # IO.puts "- - - Removed Event process \"#{state.name}\" from EventsList"
  end

  # def handle_cast({:add_room, room}, state) do
  #   {:ok, rooms} = Helpers.add_pid_if_unique(state.rooms, room)
  #   Events.Room.add_event(room, self(), state.interval)
  #   new_state = %__MODULE__{state | rooms: rooms}
  #   {:noreply, new_state}
  # end

  def handle_call(:description, _from, st), do: {:reply, st.description, st}
  def handle_call(:interval, _from, st),    do: {:reply, st.interval, st}
  def handle_call(:name, _from, st),        do: {:reply, st.name, st}
  def handle_call(:rooms, _from, st),       do: {:reply, st.rooms, st}
  def handle_call(:schedule, _from, st),    do: {:reply, st.schedule, st}

  def handle_call({:occurrences, interval}, _from, state) do
    occurrences =
      state.interval.from
      |> Schedule.first_occurrence_in_interval(state.schedule, interval)
      |> occurrences_in_interval(state.schedule, interval)

    {:reply, occurrences, state}
  end

  def handle_call(:next_occurrence, _from, state) do
    now = CalDT.now!(@timezone)
    next_occurrence =
      state.interval.from
      |> Schedule.first_occurrence_after_or_same_time(now, state.schedule)
    {:reply, next_occurrence, state}
  end

  def handle_call({:set_description, description}, _from, state) do
    new_state = %__MODULE__{state | description: description}
    {:reply, :ok, new_state}
  end

  def handle_call({:set_name, name}, _from, state) do
    new_state = %__MODULE__{state | name: name}
    {:reply, :ok, new_state}
  end

  def handle_call({:set_interval, start_erl, end_erl}, _from, state) do
    interval = Events.DateTime.create_interval(start_erl, end_erl, @timezone)
    new_state = %__MODULE__{state | interval: interval}
    {:reply, :ok, new_state}
  end

  def handle_call({:set_schedule, schedule}, _from, state) do
    new_state = %__MODULE__{state | schedule: schedule}
    {:reply, :ok, new_state}
  end

  def handle_call({:add_room, room}, _from, state) do
    {:ok, rooms} = Helpers.add_pid_if_unique(state.rooms, room)
    Events.Room.add_event(room, self(), state.interval)
    new_state = %__MODULE__{state | rooms: rooms}
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_room, room}, _from, state) do
    rooms = List.delete(state.rooms, room)
    :ok = Events.Room.remove_event(room, self())
    new_state = %__MODULE__{state | rooms: rooms}
    {:reply, :ok, new_state}
  end

  def handle_call({:conflict, interval}, _from, state) do
    conflict =
      Interval.includes?(interval, state.interval.from)
      ||
      Interval.includes?(interval, state.interval.to)
    {:reply, conflict, state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  def occurrences_in_interval(:not_in_interval, _schedule, _interval), do: []
  def occurrences_in_interval(datetime, schedule, interval) do
    Schedule.occurrences_in_interval(datetime, schedule, interval)
  end

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(event), do: GenServer.call(event, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
