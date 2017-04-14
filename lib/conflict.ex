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
  def find_conflicts(events, {new_int, new_rules}) do
    events
    |> Stream.map(fn event ->
      event
      |> guard_time_overlap(new_int)
      |> get_rules
      |> guard_by_days(new_rules)
      |> get_int
      |> guard_freq_weekly(new_rules, new_int)
      |> find_recurring
    end)
    |> filter_conflicts
    |> Enum.to_list
  end

  def guard_time_overlap(event, new_int) do
    case intervals_overlap?(Event.interval(event), new_int) do
      false -> :no_conflict
      true  -> {:ok, event}
    end
  end

  def get_rules(:no_conflict), do: :no_conflict
  def get_rules({:ok, event}) do
    ev_rules = Event.recurrence(event)
    {:ok, event, ev_rules}
  end

  def guard_by_days(:no_conflict, _), do: :no_conflict
  def guard_by_days({:ok, event, ev_rules}, new_rules) do
    days1 = Map.get(new_rules, :by_day)
    days2 = Map.get(ev_rules, :by_day)
    case maybe_common_day?(days1, days2) do
      false -> :no_conflict
      true  -> {:ok, event, ev_rules}
    end
  end

  def get_int(:no_conflict), do: :no_conflict
  def get_int({:ok, event, ev_rules}) do
    ev_int = Event.interval(event)
    {:ok, event, ev_rules, ev_int}
  end

  def guard_freq_weekly(:no_conflict, _, _), do: :no_conflict
  def guard_freq_weekly({:ok, event, ev_rules, ev_int}, new_rules, new_int) do
    case Enum.any?([new_rules, ev_rules], &weekly?/1) do
      false ->
        {:ok, event, ev_rules, ev_int}
      true ->
        days1 = find_days_of_week(new_int, new_rules)
        days2 = find_days_of_week(ev_int, ev_rules)
        case maybe_common_day?(days1, days2) do
          false -> :no_conflict
          true  -> {:ok, event, ev_rules, ev_int}
        end
    end
  end

  def find_recurring(:no_conflict), do: :no_conflict
  def find_recurring({:ok, event, ev_rules, ev_int}, new_rules, new_int) do
    ev_date = ev_int.from |> CalDT.to_date
    new_date = new_int.from |> CalDT.to_date
    ev_stream = RecurringEvents.unfold(ev_date, ev_rules)
    new_stream = RecurringEvents.unfold(new_date, new_rules)

    {:ok, date} = CalD.today_utc |> Calendar.Date.advance(18250)

    ev_occs = ev_stream |> Enum.take_while(&(Date.compare(&1, date) == :lt))
    new_occs = new_stream |> Enum.take_while(&(Date.compare(&1, date) == :lt))

    case find_first_common_date(ev_occs, new_occs) do
      false -> :no_conflict
      date -> {:ok, event}
    end
  end

  def find_first_common_date([], _), do: false
  def find_first_common_date(_, []), do: false
  def find_first_common_date([hd | tl1], [hd | tl2]), do: hd
  def find_first_common_date([date1 | tl1] = dates1, [date2 | tl2] = dates2) do
    case Date.compare(date1, date2) do
      :lt -> find_first_common_date(tl1, dates2)
      :gt -> find_first_common_date(dates1, tl2)
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
