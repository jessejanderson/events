defmodule Events.Conflict do
  @moduledoc false

  alias Events.{Conflict, Event, Room}
  alias Calendar.DateTime, as: CalDT

  @enforce_keys [:room]
  defstruct [
    :room,
    interval: %CalDT.Interval{},
    events: [],
  ]

  def create_conflict(conflict, {event, interval}, room)
  when is_pid(conflict) do
    interval_list = [Event.interval(conflict), interval]

    interval =
      interval_list
      |> Events.DateTime.find_interval_overlap
    %__MODULE__{room: room, interval: interval, events: [conflict, event]}
  end

  def create_conflicts([], _event_and_interval_tuple, _room), do: []

  def create_conflicts(conflicts, {event, %CalDT.Interval{} = interval}, room)
  when is_list(conflicts) and is_pid(event) and is_pid(room) do
    Enum.map(conflicts, &(create_conflict(&1, {event, interval}, room)))
  end

end
