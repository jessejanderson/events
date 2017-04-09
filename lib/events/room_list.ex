defmodule Events.RoomList do
  @moduledoc """
  Supervises rooms
  """

  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_room(name) do
    Supervisor.start_child(@name, [name])
  end

  def rooms do
    @name
    |> Supervisor.which_children
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(:ok) do
    children = [
      worker(Events.Room, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # def rooms do
  #   GenServer.call(@name, :rooms)
  # end

end
