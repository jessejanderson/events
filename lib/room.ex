defmodule Events.Room do
  @moduledoc false

  alias Events.{Conflict, Event, Helpers, Room, RoomList}

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

  def new(name) do
    RoomList.start_room(name)
  end

  def start_link(name) do
    # IO.puts "===== Room: \"#{name}\" #{inspect self()} :: Starting"
    GenServer.start_link(__MODULE__, name)
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

  def init(name) do
    {:ok, %Room{name: name}}
  end

  def terminate(reason, state) do
    IO.puts "!!!!! Killing Room process: \"#{state.name}\", #{inspect self()}"
    # RoomsList.remove_room(self())
    IO.puts "- - - Removed Room process \"#{state.name}\" from RoomsList"
  end

  def handle_call(:conflicts, _from, st), do: {:reply, st.conflicts, st}
  def handle_call(:events, _from, st),    do: {:reply, st.events, st}
  def handle_call(:name, _from, st),      do: {:reply, st.name, st}

  def _call(:terminate, _from, state) do
    RoomsList.remove_room(self())
    {:stop, :normal, state}
  end

  def handle_call({:set_name, name}, _from, state) do
    new_state = %__MODULE__{state | name: name}
    {:reply, :ok, new_state}
  end

  def handle_call({:add_event, event, interval}, _from, state) do
    {:ok, events} = Helpers.add_pid_if_unique(state.events, event)

    conflicts =
      state.events
      |> check_for_conflicts(interval)
      |> Conflict.create_conflicts({event, interval}, self())
      |> Enum.into(state.conflicts)

    new_state = %__MODULE__{state | events: events, conflicts: conflicts}
    {:reply, new_state, new_state}
  end

  def handle_call({:remove_event, event}, _from, state) do
    events = List.delete(state.events, event)
    new_state = %__MODULE__{state | events: events}
    {:reply, :ok, new_state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  def check_for_conflicts([], _interval), do: []
  def check_for_conflicts(events, interval) do
    Enum.filter(events, &(Event.conflict?(&1, interval)))
  end

  def add_pid_if_not_empty([], _pid),  do: []
  def add_pid_if_not_empty(list, pid), do: [pid | list]

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(room), do: GenServer.call(room, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
