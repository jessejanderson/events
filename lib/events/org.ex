defmodule Events.Org do
  @moduledoc false

  alias Events.{Helpers, OrgSupervisor}

  use Supervisor

  def start_link(org_id) do
    name = via_tuple(org_id)
    Supervisor.start_link(__MODULE__, [org_id], name: name)
  end

  def new(org_id) do
    OrgSupervisor.start_org(org_id)
  end

  def stop(org_id, reason \\ :normal, timeout \\ :infinity) do
    name = via_tuple(org_id)
    GenServer.stop(name, reason, timeout)
  end

  def init(org_id) do
    children = [
      supervisor(Events.EventList, org_id),
      supervisor(Events.RoomList, org_id)
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp via_tuple(org_id) do
    {:via, Registry, {:org_process_registry, org_id}}
  end

end
