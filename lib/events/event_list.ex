defmodule Events.EventList do
  @moduledoc """
  Supervises events
  """

  use Supervisor

  def start_link(org_id) do
    name = via_tuple(org_id)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def start_event(org_id, event_id, event_name) do
    name = via_tuple(org_id)
    Supervisor.start_child(name, [org_id, event_id, event_name])
  end

  def events(org_id) do
    org_id
    |> via_tuple
    |> Supervisor.which_children
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(_opts) do
    children = [
      worker(Events.Event, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp via_tuple(org_id) do
    {:via, Registry, {:process_registry, {:event_list, org_id}}}
  end

end
