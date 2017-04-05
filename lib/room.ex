defmodule Events.Room do
  @moduledoc false

  alias Events.{Conflict, Event, Room}
  alias Calendar.DateTime.Interval

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :name,
    conflicts: [],
    events: [],
  ]

  # +-------+
  # | A P I |
  # +-------+

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def name(room),      do: GenServer.call(room, :name)
  def conflicts(room), do: GenServer.call(room, :conflicts)
  def events(room),    do: GenServer.call(room, :events)

  def event_conflicts(room, %Interval{} = interval) do
    GenServer.call(room, {:event_conflicts, interval})
  end

  def set_name(room, name) do
    GenServer.call(room, {:set_name, name})
  end

  def add_conflict(room, conflict) when is_pid(conflict) do
    IO.puts "received initial add_conflict/2 call"
    IO.inspect room
    IO.inspect conflict
    GenServer.call(room, {:add_conflicts, [conflict]})
  end

  def add_conflicts(room, conflicts) when is_list(conflicts) do
    IO.puts "received add_conflicts/2 call"
    GenServer.call(room, {:add_conflicts, conflicts})
  end

  def add_event(room, {:no_return, event}) when is_pid(event)do
    GenServer.call(room, {:no_return, :add_event, event})
  end

  def add_event(room, event) when is_pid(event)do
    GenServer.call(room, {:add_events, [event]})
  end

  def add_events(room, events) when is_list(events) do
    GenServer.call(room, {:add_events, events})
  end

  def list_events(room) do
    GenServer.call(room, :list_events)
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
    IO.puts "Starting Room process (name: #{name})"
    {:ok, %Room{name: name}}
  end

  # GET STATE
  # =========

  def handle_call(:name, _from, state) do
    {:reply, state.name, state}
  end

  def handle_call(:events, _from, state) do
    {:reply, state.events, state}
  end

  def handle_call(:conflicts, _from, state) do
    {:reply, state.conflicts, state}
  end

  def handle_call({:event_conflicts, interval}, _from, state) do
    conflict =
      state.events
      |> find_events_with_conflicts(interval)
      |> spawn_conflict(self())

    %Room{state | conflicts: [conflict | state.conflicts]}
    |> reply_tuple
  end

  def find_events_with_conflicts(events, interval) do
    Enum.filter(events, &(Event.conflict?(&1, interval)))
  end

  def spawn_conflict(events, room) do
    {:ok, conflict} = Conflict.start_link(room)
    Conflict.add_events(conflict, events)
    conflict
  end

  # SET STATE
  # =========

  def handle_call({:set_name, name}, _from, state) do
    %Room{state | name: name}
    |> reply_tuple
  end

  def handle_call({:no_return, :add_event, event}, _from, state) do
    event
    |> add_event_to_room_state(state)
    |> reply_tuple
  end

  def handle_call({:add_events, events}, _from, state) do
    events
    |> add_self_to_events
    |> add_events_to_room_state(state)
    |> reply_tuple
  end

  def handle_call({:add_conflicts, conflicts}, _from, state) do
    IO.puts "Handling {:add_conflicts, conflicts} call"
    conflicts
    |> add_conflicts_to_room_state(state)
    |> reply_tuple
    # |> add_self_to_conflict
    # conflicts = [conflict | state.conflicts] |> List.flatten
    # %Room{state | conflicts: conflicts}
    # |> reply_tuple
  end

  def handle_call(:list_events, _from, state) do
    events = Enum.map(state.events, &Event.name/1)
    {:reply, events, state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  defp reply_tuple(state), do: {:reply, state, state}

  defp check_already_exists(event, state) do
    case event in state.events do
      true  -> {:exists, event}
      false -> {:new, event}
    end
  end

  defp add_conflict_to_room_state(conflict, state) do
    case conflict in state.conflicts do
      true -> state
      false -> Map.update!(state, :conflicts, &([conflict | &1]))
    end
  end

  defp add_conflicts_to_room_state(conflicts, state) do
    Enum.reduce(conflicts, state, &(add_conflict_to_room_state(&1, &2)))
  end

  defp add_self_to_event(event) do
    Event.add_room(event, {:no_return, self()})
    event
  end

  defp add_self_to_events(events) do
    Enum.each(events, &add_self_to_event/1)
    events
  end

  defp add_event_to_room_state(event, state) do
    case event in state.events do
      true -> state
      false -> Map.update!(state, :events, &([event | &1]))
    end
  end

  defp add_events_to_room_state(events, state) do
    Enum.reduce(events, state, &(add_event_to_room_state(&1, &2)))
  end

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(room), do: GenServer.call(room, :wtf)
  def handle_call(:wtf, _from, state), do: reply_tuple(state)

end
