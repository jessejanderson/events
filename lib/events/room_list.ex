defmodule Events.RoomList do
  @moduledoc """
  Supervises rooms
  """

  use Supervisor

  def start_link(org_id) do
    name = via_tuple(org_id)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def start_room(org_id, room_name) do
    name = via_tuple(org_id)
    Supervisor.start_child(name, [room_name])
  end

  # def rooms do
  #   @name
  #   |> Supervisor.which_children
  #   |> Enum.map(&(elem(&1, 1)))
  # end

  def init(_opts) do
    children = [
      worker(Events.Room, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp via_tuple(org_id) do
    {:via, Registry, {:org_process_registry, {org_id, :room_list}}}
  end

  # def rooms do
  #   GenServer.call(@name, :rooms)
  # end

end
