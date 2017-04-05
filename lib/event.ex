defmodule Events.Event do
  @moduledoc false

  alias Events.{Conflict, Event, Helpers, Room}

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :description,
    :name,
    interval: %Calendar.DateTime.Interval{},
    rooms: []
  ]

  # TODO: get dynamic tz from org or local
  @timezone "America/Los_Angeles"

  # +-------+
  # | A P I |
  # +-------+

  def start_link(name) do
    IO.puts "===== Starting Event process: \"#{name}\", #{inspect self()}"
    GenServer.start_link(__MODULE__, name)
  end

  def list_rooms(event), do: GenServer.call(event, :list_rooms)

  def set_interval(event, start_erl, end_erl) do
    GenServer.call(event, {:set_interval, start_erl, end_erl})
  end

  def add_room(event, room) do
    GenServer.call(event, {:add_room, room})
  end

  def remove_room(event, room) do
    GenServer.call(event, {:remove_room, room})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
    IO.puts "- - - Initializing Event process: \"#{name}\", #{inspect self()}"
    {:ok, %__MODULE__{name: name}}
  end

  def handle_call(:list_rooms, _from, state) do
    {:reply, state.rooms, state}
  end

  def handle_call({:set_interval, start_erl, end_erl}, _from, state) do
    interval = Events.DateTime.create_interval(start_erl, end_erl, @timezone)
    new_state = %__MODULE__{state | interval: interval}
    {:reply, :ok, new_state}
  end

  def handle_call({:add_room, room}, _from, state) when is_pid(room) do
    {:ok, rooms} = Helpers.add_pid_if_unique(state.rooms, room)
    :ok = Events.Room.add_event(room, self())
    new_state = %__MODULE__{state | rooms: rooms}
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_room, room}, _from, state) when is_pid(room) do
    rooms = List.delete(state.rooms, room)
    :ok = Events.Room.remove_event(room, self())
    new_state = %__MODULE__{state | rooms: rooms}
    {:reply, :ok, new_state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(event), do: GenServer.call(event, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
