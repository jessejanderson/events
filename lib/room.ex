defmodule Events.Room do
  use GenServer
  @enforce_keys [:name]
  defstruct [:name, approvers: [], events: []]

  alias Events.Room
  alias Events.Event

  # +-------+
  # | A P I |
  # +-------+

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def add_event(room, event) do
    GenServer.call(room, {:add_event, event})
  end

  def list_events(room) do
    GenServer.call(room, :list_events)
  end

  def wtf(room), do: GenServer.call(room, :wtf)

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
    {:ok, %Room{name: name}}
  end

  def handle_call({:add_event, event}, _from, state) do
    new_state = %Room{state | events: [event|state.events]}
    {:reply, new_state, new_state}
  end

  def handle_call(:list_events, _from, state) do
    events = Enum.map(state.events, &Event.name/1)
    {:reply, events, state}
  end

  def handle_call(:wtf, _from, state) do
    {:reply, state, state}
  end
end
