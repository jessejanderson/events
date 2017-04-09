defmodule Events.EventList do
  @moduledoc """
  Supervises events
  """

  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_event(name) do
    Supervisor.start_child(@name, [name])
  end

  def events do
    @name
    |> Supervisor.which_children
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(:ok) do
    children = [
      worker(Events.Event, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # def events do
  #   GenServer.call(@name, :events)
  # end

end
