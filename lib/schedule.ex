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

  defstruct [
    :starts, # %DateTime{} to ensure timezone
    type: :one_time, # :daily, :weekly, :monthly
    days_of_week: [], # :sunday, :monday, ..., :saturday
    days_of_month: [], # 1, 2, ..., 30, 31
    ends: :never, # || {:date, %DateTime{}} || {:sessions, 5}
    frequency: 1, # 1 = every, 2 = every other, 3 = every third, etc
    weeks_of_month: [], # 1, 2, 3, 4, 5, :last
  ]


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
