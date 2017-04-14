defmodule Events.Conflict do
  @moduledoc false

  alias Events.{Conflict, Event, Room}
  alias Calendar.DateTime, as: CalDT
  alias Calendar.Date, as: CalD

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

  # def create_conflict(conflict, {event, interval}, room)
  # when is_pid(conflict) do
  #   interval_list = [Event.interval(conflict), interval]

  #   interval =
  #     interval_list
  #     |> Events.DateTime.find_interval_overlap
  #   %__MODULE__{room: room, interval: interval, events: [conflict, event]}
  # end

  def create_conflict(ev1, ev2), do: {ev1, ev2}

  def create_conflicts(event_list, event) do
    event_list
    |> Enum.map(&(create_conflict(&1, event)))
  end

  # def create_conflicts([], _event, _interval, _room), do: []

  # def create_conflicts(conflicts, event, %CalDT.Interval{} = interval, room)
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
      |> guard_time_overlap(interval)
      |> guard_by_days(rules)
      |> guard_freq_weekly(interval, rules)
    end)
    |> filter_conflicts
    |> Enum.to_list
  end

  def guard_time_overlap(event, interval) do
    case intervals_overlap?(Event.interval(event), interval) do
      false -> :no_conflict
      true  -> {:ok, event}
    end
  end

  def guard_by_days(:no_conflict, _), do: :no_conflict
  def guard_by_days({:ok, event}, rules) do
    rules2 = Event.recurrence(event)
    days1 = Map.get(rules, :by_day)
    days2 = Map.get(rules2, :by_day)
    check_maybe_common_day?(days1, days2, event)
  end

  def guard_freq_weekly(:no_conflict, _, _), do: :no_conflict
  def guard_freq_weekly({:ok, event}, interval, rules) do
    rules2 = Event.recurrence(event)

    case Enum.any?([rules, rules2], &weekly?/1) do
      true ->
        days1 = find_days_of_week(interval, rules)
        days2 = find_days_of_week(Event.interval(event), rules2)
        check_maybe_common_day?(days1, days2, event)
      false ->
        {:ok, event}
    end
  end

  def find_days_of_week(interval, %{by_day: day})
      when is_atom(day) do
    [find_day_of_week(interval.from), day] |> Enum.uniq
  end

  def find_days_of_week(interval, %{by_day: days})
      when is_list(days) do
    [find_day_of_week(interval.from) | days] |> Enum.uniq
  end

  def find_days_of_week(interval, _) do
    [find_day_of_week(interval.from)]
  end

  def find_day_of_week(interval) do
    interval |> CalD.day_of_week_name |> convert_to_atom
  end

  defp convert_to_atom(str), do: str |> String.downcase |> String.to_atom

  def filter_conflicts(list) do
    list
    |> Stream.filter_map(
      &(&1 != :no_conflict),
    &(elem(&1, 1)))
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

  def check_maybe_common_day?(days1, days2, event) do
    case maybe_common_day?(days1, days2) do
      false -> :no_conflict
      true  -> {:ok, event}
    end
  end

  def maybe_common_day?(nil, _), do: false
  def maybe_common_day?(_, nil), do: false
  def maybe_common_day?(day, day)   when is_atom(day),  do: true
  def maybe_common_day?(days, days) when is_list(days), do: true
  def maybe_common_day?(day1, day2)
      when is_atom(day1) and is_atom(day2) do
    false
  end
  def maybe_common_day?(days, day)
      when is_atom(day) and is_list(days) do
    day in days
  end
  def maybe_common_day?(day, days)
      when is_atom(day) and is_list(days) do
    day in days
  end
  def maybe_common_day?(days1, days2) do
    Enum.any?(days1, &(&1 in days2))
  end
  def maybe_common_day?(_, _), do: true

  def weekly?(%{freq: :weekly}), do: true
  def weekly?(_rules), do: false

end
