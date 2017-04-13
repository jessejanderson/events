defmodule RecurrenceTest do
  use ExUnit.Case
  alias Events.{Event, Org}

  @event_name "My First Event"
  @date1 {{2018, 1, 1}, {1, 0, 0}}
  @date2 {{2018, 1, 1}, {2, 0, 0}}
  @date_1_1_18 {{2018, 1, 1}, {1, 0, 0}}
  @date_1_7_18 {{2018, 1, 7}, {1, 0, 0}}
  @date_1_30_18 {{2018, 1, 30}, {1, 0, 0}}
  @date_1_1_20 {{2020, 1, 1}, {1, 0, 0}}
  @tz "America/Los_Angeles"

  setup do
    org_id = Enum.random(1..9999)
    event_id = Enum.random(1..9999)

    {:ok, _org} = Org.new(org_id)
    {:ok, event} = Event.new(org_id, event_id, @event_name)

    Event.set_interval(event, @date1, @date2)

    {:ok, event: event, org_id: org_id, event_id: event_id}
  end

  test "Set every-day rules for event", %{event: event} do
    rules = %{freq: :daily}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
  end

  test "Set every-other-day rules for event", %{event: event} do
    rules = %{freq: :daily, interval: 2}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
  end

  test "Set every-other-day rules as a list for event", %{event: event} do
    rules = %{freq: :daily, interval: 2}
    Event.set_recurrence(event, freq: :daily, interval: 2)
    assert rules == Event.recurrence(event)
  end

  test "Set every-week rules for event", %{event: event} do
    rules = %{freq: :weekly, day_of_week: [:monday]}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
  end

  test "Event repeats every day", %{event: event} do
    rules = %{freq: :daily}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_7_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 7 == Enum.count(occurrences)
  end

  test "Event repeats every other day", %{event: event} do
    rules = %{freq: :daily, interval: 2}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_7_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 4 == Enum.count(occurrences)
  end

  test "Event repeats every week", %{event: event} do
    rules = %{freq: :weekly}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_30_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 5 == Enum.count(occurrences)
  end

  test "Event repeats every other week", %{event: event} do
    rules = %{freq: :weekly, interval: 2}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_30_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 3 == Enum.count(occurrences)
  end

  test "Event repeats every Mon, Wed, Fri", %{event: event} do
    rules = %{freq: :weekly, by_day: [:monday, :wednesday, :friday]}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_30_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 13 == Enum.count(occurrences)
  end

  test "Event repeats every weekday", %{event: event} do
    weekdays = [:monday, :tuesday, :wednesday, :thursday, :friday]
    rules = %{freq: :weekly, by_day: weekdays}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_30_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 22 == Enum.count(occurrences)
  end

  test "Event repeats every weekend day", %{event: event} do
    rules = %{freq: :weekly, by_day: [:saturday, :sunday]}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_7_18, @date_1_30_18, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 7 == Enum.count(occurrences)
  end

  test "Event repeats every month", %{event: event} do
    rules = %{freq: :monthly}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 25 == Enum.count(occurrences)
  end

  test "Event repeats every quarter", %{event: event} do
    rules = %{freq: :monthly, interval: 3}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 9 == Enum.count(occurrences)
  end

  test "Event repeats every year", %{event: event} do
    rules = %{freq: :yearly}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 3 == Enum.count(occurrences)
  end

  # +---------------+
  # | P E N D I N G |
  # +---------------+

  @tag :pending
  test "Event repeats every first monday of month", %{event: event} do
    rules = %{freq: :monthly, by_day: :monday, by_week: 1}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 24 == Enum.count(occurrences)
  end

  @tag :pending
  test "Event repeats every last monday of month", %{event: event} do
    rules = %{freq: :monthly, by_day: :monday, by_week: -1}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 24 == Enum.count(occurrences)
  end

  @tag :pending
  test "Event repeats every 5th monday of month", %{event: event} do
    rules = %{freq: :monthly, by_day: :monday, by_week: 5}
    Event.set_recurrence event, rules
    assert rules == Event.recurrence(event)
    interval = Events.DateTime.create_interval(@date_1_1_18, @date_1_1_20, @tz)
    {:ok, occurrences} = Event.occurrences(event, interval)
    assert 9 == Enum.count(occurrences)
  end
end
