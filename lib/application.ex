defmodule Events.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Events.Supervisor.start_link
  end
end
