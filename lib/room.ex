defmodule Events.Room do
  @moduledoc false

  alias Events.{Conflict, Event, Room}

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :name,
    approvers: [],
    events: []
  ]

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

  def add_event(room, {:no_return, event}) when is_pid(event)do
    GenServer.call(room, {:no_return, :add_event, event})
  end

  def add_event(room, event) when is_pid(event)do
    GenServer.call(room, {:add_event, event})
  end

  def add_events(room, events) when is_list(events) do
    GenServer.call(room, {:add_events, events})
  end

  def add_approver(room, approver) when is_pid(approver) do
    GenServer.call(room, {:add_approver, approver})
  end

  def add_approvers(room, approvers) when is_list(approvers) do
    GenServer.call(room, {:add_approvers, approvers})
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

  def handle_call({:no_return, :add_event, event}, _from, state) do
    event
    |> add_event_to_room_state(state)
    |> reply_tuple
  end

  def handle_call({:add_event, event}, _from, state) do
    event
    |> add_self_to_event
    |> add_event_to_room_state(state)
    |> reply_tuple
  end

  def handle_call({:add_events, events}, _from, state) do
    events
    # |> add_self_to_events
    |> add_events_to_room_state(state)
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

  defp check_already_exists(event, state) do
    case event in state.events do
      true  -> {:exists, event}
      false -> {:new, event}
    end
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

  def wtf(event), do: GenServer.call(event, :wtf)
  def handle_call(:wtf, _from, state), do: reply_tuple(state)

end
