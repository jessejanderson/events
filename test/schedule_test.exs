defmodule ScheduleTest do
  use ExUnit.Case
  alias Events.{Event, Org, Room}
  alias Events.Event.Schedule
  # alias Calendar.DateTime, as: CalDT

  doctest Schedule

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2018, 1, 1}, {1, 0, 0}}
  @date2 {{2018, 1, 1}, {2, 0, 0}}

  setup do
    org_id = Enum.random(1..9999)
    room_id = Enum.random(1..9999)
    event_id = Enum.random(1..9999)

    {:ok, _org} = Org.new(org_id)
    {:ok, room} = Room.new(org_id, room_id, @room_name)
    {:ok, room: room, org_id: org_id, room_id: room_id}
    {:ok, event} = Event.new(org_id, event_id, @event_name)

    {:ok, event: event, room: room, org_id: org_id}
  end

  test "Event repeats every day", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(event, %Schedule{type: :daily})

    schedule = %Schedule{
      days_of_week: [],
      days_of_month: [],
      ends: :never,
      frequency: 1,
      type: :daily,
      weeks_of_month: [],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 1, 7}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 7 == Enum.count(occurrences)
  end

  test "Events repeats every other day", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(event, %Schedule{type: :daily, frequency: 2})

    schedule = %Schedule{
      days_of_week: [],
      days_of_month: [],
      ends: :never,
      frequency: 2,
      type: :daily,
      weeks_of_month: [],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 1, 7}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 4 == Enum.count(occurrences)
  end

  test "Event repeats every week", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :weekly,
        days_of_week: [:monday]
      })

    schedule = %Schedule{
      days_of_week: [:monday],
      days_of_month: [],
      ends: :never,
      frequency: 1,
      type: :weekly,
      weeks_of_month: [],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 1, 30}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 5 == Enum.count(occurrences)
  end

  test "Event repeats multiple days every week", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :weekly,
        days_of_week: [:monday, :wednesday]
      })

    schedule = %Schedule{
      days_of_week: [:monday, :wednesday],
      days_of_month: [],
      ends: :never,
      frequency: 1,
      type: :weekly,
      weeks_of_month: [],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 1, 30}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 10 == Enum.count(occurrences)
  end

  test "Event repeats every other week", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :weekly,
        days_of_week: [:monday],
        frequency: 2
      })

    schedule = %Schedule{
      days_of_week: [:monday],
      days_of_month: [],
      ends: :never,
      frequency: 2,
      type: :weekly,
      weeks_of_month: [],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 1, 30}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 3 == Enum.count(occurrences)
  end

  test "Event repeats every month", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :monthly,
        days_of_week: [:monday],
        weeks_of_month: [1]
      })

    schedule = %Schedule{
      days_of_week: [:monday],
      days_of_month: [],
      ends: :never,
      frequency: 1,
      type: :monthly,
      weeks_of_month: [1],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 6, 1}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 6 == Enum.count(occurrences)
  end

  test "Event repeats every other month", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :monthly,
        days_of_week: [:monday],
        frequency: 2,
        weeks_of_month: [1]
      })

    schedule = %Schedule{
      days_of_week: [:monday],
      days_of_month: [],
      ends: :never,
      frequency: 2,
      type: :monthly,
      weeks_of_month: [1],
    }

    interval =
      Events.DateTime.create_interval(
        @date1,
        {{2018, 6, 1}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert schedule == Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 3 == Enum.count(occurrences)
  end
end
