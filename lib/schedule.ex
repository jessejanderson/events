defmodule Events.Event.Schedule do
  @moduledoc """
  Recurence schedule for events

  ## Examples

  Every other day:
  %Schedule{
    ends: :never,
    frequency: 2,
    starts: %DateTime{},
    type: :daily
  }

  Every other Monday:
  %Schedule{
    days_of_week: [:monday],
    ends: :never,
    frequency: 2,
    starts: %DateTime{},
    type: :weekly
  }

  Every Tuesday:
  %Schedule{
    days_of_week: [:tuesday],
    ends: :never,
    frequency: 1,
    starts: %DateTime{},
    type: :weekly
  }

  Mon-sat every week:
  %Schedule{
    days_of_week:
      [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday],
    ends: :never,
    frequency: 1,
    starts: %DateTime{},
    type: :weekly
  }

  Every 3rd of the month:
  %Schedule{
    date_of_month: [3]
    ends: :never,
    frequency: 1,
    starts: %DateTime{},
    type: :monthly
  }

  1st and 3rd every 2 months:
  %Schedule{
    date_of_month: [1, 3]
    ends: :never,
    frequency: 2,
    starts: %DateTime{},
    type: :monthly
  }

  On the 3rd Tuesday of every 4th month (trimester) for 6 sessions:
  %Schedule{
    day_of_week: [:tuesday]
    ends: {sessions, 6},
    frequency: 4,
    starts: %DateTime{},
    type: :monthly
    weeks_of_month: [3]
  }
  """

  alias Events.Event.Schedule
  alias Calendar.DateTime, as: CalDT

  defstruct [
    :starts, # %DateTime{} to ensure timezone
    type: :one_time, # :daily, :weekly, :monthly
    days_of_week: [], # :sunday, :monday, ..., :saturday
    days_of_month: [], # 1, 2, ..., 30, 31
    ends: :never, # || {:date, %DateTime{}} || {:sessions, 5}
    frequency: 1, # 1 = every, 2 = every other, 3 = every third, etc
    weeks_of_month: [], # 1, 2, 3, 4, 5, :last
  ]

  def first_occurrence_in_interval(
    %DateTime{} = from, %Schedule{} = schedule, %CalDT.Interval{} = interval) do
    after_or_same = CalDT.after?(from, interval.from)
    first_occurrence_in_interval(from, schedule, interval, after_or_same)
  end

  def first_occurrence_in_interval(from, schedule, interval, true) do
    case CalDT.Interval.includes?(interval, from) do
      true ->  from
      false -> :not_in_interval
    end
  end

  def first_occurrence_in_interval(from, schedule, interval, false) do
    from
    |> advance(schedule)
    |> first_occurrence_in_interval(schedule, interval)
  end

  def occurrences_in_interval(datetime, schedule, interval) do
    occurrences_in_interval(datetime, schedule, interval, [datetime])
  end

  def occurrences_in_interval(datetime, schedule, interval, occurrences) do
    new_datetime = datetime |> advance(schedule)
    case before_or_same_time?(new_datetime, interval.to) do
      true ->
        occurrences = [new_datetime | occurrences]
        occurrences_in_interval(new_datetime, schedule, interval, occurrences)
      false -> occurrences
    end
  end

  def after_or_same_time?(%DateTime{} = dt1, %DateTime{} = dt2) do
    CalDT.after?(dt1, dt2) || CalDT.same_time?(dt1, dt2)
  end

  def before_or_same_time?(%DateTime{} = dt1, %DateTime{} = dt2) do
    CalDT.before?(dt1, dt2) || CalDT.same_time?(dt1, dt2)
  end

  def advance(
    %DateTime{} = datetime,
    %Schedule{ends: :never, type: :daily} = schedule
  ) do
    Timex.shift(datetime, days: schedule.frequency)
  end

  # %Schedule{
  #   ends: :never,
  #   frequency: 1,
  #   starts: %DateTime{},
  #   type: :daily
  # }

  # +---------------------------------------------------+
  # | "Recurring Events for Calendars" by Martin Fowler |
  # +---------------------------------------------------+

  # def occurences(event, daterange) do
  #   # return a set of dates
  # end

  # def next_occurrence(event, date) do
  #   # return next scheduled occurence from now
  # end

  # def occurring?(event, date) do
  #   # return if occuring on given date (timezone?)
  # end
end
