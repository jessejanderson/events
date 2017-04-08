defmodule ScheduleTest do
  use ExUnit.Case
  alias Events.{Event, EventsList, Room, RoomsList}
  alias Events.Event.Schedule
  # alias Calendar.DateTime, as: CalDT

  doctest Schedule

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}

  setup do
    EventsList.start_link
    RoomsList.start_link
    {:ok, event1} = Event.start_link(@event_name)
    {:ok, room1} = Room.start_link(@room_name)
    {:ok, event1: event1, room1: room1}
  end

  test "Make a daily event", %{event1: event1} do
    Event.set_interval(event1, @date1, @date2)
    Event.set_schedule(
      event1,
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

    assert ^schedule = Event.schedule(event1)

    occurrences = Event.occurrences(event1, interval)

    assert 7 = Enum.count(occurrences)
  end
end
