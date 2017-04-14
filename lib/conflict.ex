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

  # def create_conflict(conflict, {event, interval}, room)
  # when is_pid(conflict) do
  #   interval_list = [Event.interval(conflict), interval]

  #   interval =
  #     interval_list
  #     |> Events.DateTime.find_interval_overlap
  #   %__MODULE__{room: room, interval: interval, events: [conflict, event]}
  # end

  # def create_conflicts([], _event_and_interval_tuple, _room), do: []

  # def create_conflicts(conflicts, {event, %CalDT.Interval{} = interval}, room)
  # when is_list(conflicts) and is_pid(event) and is_pid(room) do
  #   Enum.map(conflicts, &(create_conflict(&1, {event, interval}, room)))
  # end

  # ==============================

  def check_room_for_conflicts(room, interval, rules)
  when is_pid(room) do
    find_conflicts(Room.events(room), {interval, rules})
  end

  def find_conflicts([], _), do: []
  def find_conflicts(conflicts, {interval, rules}) do
    conflicts
    |> Stream.map(fn event ->
      event
      |> check_overlap(interval)
      |> check_by_days(rules)
    end)
    |> filter_conflicts
    |> Enum.to_list
  end

  def filter_conflicts(list) do
    list
    |> Stream.filter_map(
      &(&1 != :no_conflict),
      &(elem(&1, 1)))
  end

  def check_overlap(event, interval) do
    case intervals_overlap?(Event.interval(event), interval) do
      false -> :no_conflict
      true  -> {:ok, event}
    end
  end

  def check_by_days(:no_conflict, _), do: :no_conflict
  def check_by_days({:ok, event}, rules2) do
    rules1 = Event.recurrence(event)
    case same_day_of_week_possible?(rules1, rules2) do
      false -> :no_conflict
      true  -> {:ok, event}
    end
  end

  # ==============================

  def intervals_overlap?(int, int), do: true
  def intervals_overlap?(int1, int2) do
    before_or_same?(int1.from, int2.to)
    &&
    after_or_same?(int1.to, int2.from)
  end

  def after_or_same?(time, time), do: true
  def after_or_same?(tm1, tm2), do: :gt == Time.compare(tm1, tm2)

  def before_or_same?(time, time), do: true
  def before_or_same?(tm1, tm2), do: :lt == Time.compare(tm1, tm2)

  def same_day_of_week_possible?(%{by_day: days}, %{by_day: days}), do: true
  def same_day_of_week_possible?(%{by_day: days1}, %{by_day: days2}) do
    Enum.any?(days1, &(&1 in days2))
  end
  def same_day_of_week_possible?(_, _), do: true

end
