defmodule Events.Application do
  @moduledoc false

  use Application

  @name __MODULE__

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Registry, [:unique, :process_registry]),
      supervisor(Events.OrgSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: @name]
    Supervisor.start_link(children, opts)
  end

end
