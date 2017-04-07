defmodule Events.EventsList do
  @moduledoc """
    Holds all the events
  """

  alias Events.Helpers

  use GenServer

  @name __MODULE__

  # +-------+
  # | A P I |
  # +-------+

  def start_link(events \\ []) when is_list(events) do
    IO.puts "===== EVENTS: #{inspect self()} :: Starting"
    GenServer.start_link(__MODULE__, events, name: @name)
  end

  def events do
    GenServer.call(@name, :events)
  end

  def add_event(event) when is_pid(event) do
    GenServer.call(@name, {:add_event, event})
  end

  def remove_event(event) when is_pid(event) do
    GenServer.call(@name, {:remove_event, event})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(events) do
    IO.puts "- - - EVENTS: #{inspect self()} :: Initializing"
    {:ok, events}
  end

  def handle_call(:events, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_event, event}, _from, state) do
    {:ok, new_state} = Helpers.add_pid_if_unique(state, event)
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_event, event}, _from, state) do
    new_state = List.delete(state, event)
    {:reply, :ok, new_state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf, do: GenServer.call(@name, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
