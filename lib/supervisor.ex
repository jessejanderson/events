defmodule Events.Supervisor do
  @moduledoc """
  Event Supervisor
  """

  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      supervisor(Events.EventList, []),
      supervisor(Events.RoomList, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
