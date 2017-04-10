defmodule Events.Room do
  @moduledoc false

  alias Events.{Conflict, Event, Helpers, RoomList}

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :id,
    :name,
    conflicts: [],
    events: [],
  ]

  # +-------+
  # | A P I |
  # +-------+

  # TODO: generate room_id automatically
  def new(org_id, room_id, room_name) do
    RoomList.start_room(org_id, room_id, room_name)
  end

  def start_link(org_id, room_id, room_name) do
    name = via_tuple(org_id, room_id)
    GenServer.start_link(__MODULE__, {room_id, room_name}, name: name)
  end

  def stop(room, reason \\ :normal, timeout \\ :infinity) do
    # reason can be {:shutdown, erl_term} to save state on death
    GenServer.stop(room, reason, timeout)
  end

  def conflicts(room), do: GenServer.call(room, :conflicts)
  def events(room),    do: GenServer.call(room, :events)
  def name(room),      do: GenServer.call(room, :name)

  def set_name(room, name) do
    GenServer.call(room, {:set_name, name})
  end

  def add_event(room, event, interval) when is_pid(event) do
    GenServer.call(room, {:add_event, event, interval})
  end

  def remove_event(room, event) when is_pid(event) do
    GenServer.call(room, {:remove_event, event})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init({id, name}) do
    {:ok, %__MODULE__{id: id, name: name}}
  end

  def terminate(reason, state) do
    IO.puts "!!!!! Killing Room process: \"#{state.name}\", #{inspect self()}"
    IO.puts "! ! ! Reason: #{reason}"
  end

  def handle_call(:conflicts, _from, st), do: {:reply, st.conflicts, st}
  def handle_call(:events, _from, st),    do: {:reply, st.events, st}
  def handle_call(:name, _from, st),      do: {:reply, st.name, st}

  def handle_call({:set_name, name}, _from, state) do
    new_state = %__MODULE__{state | name: name}
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:add_event, event, interval}, _from, state) do
    new_state = do_add_event(state, event, interval)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:remove_event, event}, _from, state) do
    new_state = do_remove_event(state, event)
    {:reply, {:ok, new_state}, new_state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  defp do_add_event(state, event, interval) do
    {:ok, events} = Helpers.add_pid_if_unique(state.events, event)
    conflicts =
      state.events
      |> check_for_conflicts(interval)
      |> Conflict.create_conflicts({event, interval}, self())
      |> Enum.into(state.conflicts)
    %__MODULE__{state | events: events, conflicts: conflicts}
  end

  defp do_remove_event(state, event) do
    events =
      state.events
      |> List.delete(event)
    %__MODULE__{state | events: events}
  end

  defp check_for_conflicts([], _interval), do: []
  defp check_for_conflicts(events, interval) do
    Enum.filter(events, &(Event.conflict?(&1, interval)))
  end

  defp via_tuple(org_id, room_id) do
    {:via, Registry, {:process_registry, {:room, org_id, room_id}}}
  end

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(room), do: GenServer.call(room, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
