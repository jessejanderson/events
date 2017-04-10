defmodule ScheduleTest do
  use ExUnit.Case
  alias Events.{Event, Org, Room}
  alias Events.Event.Schedule
  # alias Calendar.DateTime, as: CalDT

  doctest Schedule

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}

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

  test "Make a daily event", %{event: event} do
    Event.set_interval(event, @date1, @date2)
    Event.set_schedule(
      event,
      %Schedule{
        type: :daily,
      }
    )

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
        {{2020, 1, 7}, {1, 0, 0}},
        "America/Los_Angeles"
      )

    assert ^schedule = Event.schedule(event)

    {:ok, occurrences} = Event.occurrences(event, interval)

    assert 7 = Enum.count(occurrences)
  end
end
