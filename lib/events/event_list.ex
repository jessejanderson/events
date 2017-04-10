defmodule Events.EventList do
  @moduledoc """
  Supervises events
  """

  use Supervisor

  def start_link(org_id) do
    name = via_tuple(org_id)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def start_event(org_id, event_name) do
    name = via_tuple(org_id)
    Supervisor.start_child(name, [event_name])
  end

  # def events do
  #   @name
  #   |> Supervisor.which_children
  #   |> Enum.map(&(elem(&1, 1)))
  # end

  def init(_opts) do
    children = [
      worker(Events.Event, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp via_tuple(org_id) do
    {:via, Registry, {:org_process_registry, {org_id, :event_list}}}
  end

  # def events do
  #   GenServer.call(@name, :events)
  # end

end
