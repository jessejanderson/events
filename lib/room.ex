defmodule Events.Room do
  @moduledoc false

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

  def name(event),      do: GenServer.call(event, :name)
  def events(event),    do: GenServer.call(event, :events)
  def approvers(event), do: GenServer.call(event, :approvers)

  def set_name(event, name) do
    GenServer.call(event, {:set_name, name})
  end

  def add_event(room, event) do
    GenServer.call(room, {:add_event, event})
  end

  def add_approver(approver, event) do
    GenServer.call(approver, {:add_approver, event})
  end

  def list_events(room) do
    GenServer.call(room, :list_events)
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
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

  def handle_call(:approvers, _from, state) do
    {:reply, state.approvers, state}
  end

  # SET STATE
  # =========

  def handle_call({:set_name, name}, _from, state) do
    %Room{state | name: name}
    |> reply_tuple
  end

  def handle_call({:add_event, event}, _from, state) do
    events = [event | state.events] |> List.flatten
    %Room{state | events: events}
    |> reply_tuple
  end

  def handle_call({:add_approver, approver}, _from, state) do
    approvers = [approver | state.approvers] |> List.flatten
    %Room{state | approvers: approvers}
    |> reply_tuple
  end

  def handle_call(:list_events, _from, state) do
    events = Enum.map(state.events, &Event.name/1)
    {:reply, events, state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  defp reply_tuple(state), do: {:reply, state, state}

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

end
