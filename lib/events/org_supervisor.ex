defmodule Events.OrgSupervisor do
  @moduledoc """
  Org Supervisor
  """

  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def start_org(org_id) do
    Supervisor.start_child(@name, [org_id])
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(@name, reason, timeout)
  end

  def init(_opts) do
    children = [
      supervisor(Events.Org, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def via_tuple(org_id) do
    {:via, Registry, {:process_registry, org_id}}
  end
end
