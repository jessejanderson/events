defmodule Events.Conflict do
  @moduledoc false

  alias Events.{Conflict, Event, Room}

  defstruct [
    events: [],
    room: []
  ]

  # +-------+
  # | A P I |
  # +-------+

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(:ok) do
    {:ok, %Conflict{}}
  end

end
