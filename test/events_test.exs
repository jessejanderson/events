defmodule EventsTest do
  use ExUnit.Case

  doctest Events

  alias Events.{Event, EventList, Room, RoomList}

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}
  @date3 {{2020, 1, 1}, {3, 0, 0}}
  @date4 {{2020, 1, 1}, {4, 0, 0}}
  # @date5 {{2020, 1, 1}, {5, 0, 0}}
  # @date6 {{2020, 1, 1}, {6, 0, 0}}

  setup do
    {:ok, event1} = Event.new(@event_name)
    {:ok, room1} = Room.new(@room_name)
    {:ok, event1: event1, room1: room1}
  end

  test "Add a room to an event", %{event1: event1, room1: room1} do
    Event.set_interval(event1, @date1, @date2)
    Event.add_room(event1, room1)

    assert event1 in Room.events(room1)

    assert room1 in RoomList.rooms
    assert room1 in Event.rooms(event1)
  end

  test "Add a room to 2 events and create a conflict",
  %{event1: event1, room1: room1} do
    {:ok, event2} = Event.new("My Second Event")
    Event.set_interval(event1, @date1, @date3)
    Event.set_interval(event2, @date2, @date4)

    Event.add_room(event1, room1)
    Event.add_room(event2, room1)

    conflict_events =
      room1 |> Room.conflicts |> hd |> Map.get(:events)

    assert event1 in conflict_events
    assert event2 in conflict_events
  end


  test "generate 20 events and add the same room to create conflicts",
  %{event1: event1, room1: room1} do
    Event.set_interval(event1, @date1, @date4)
    Event.add_room(event1, room1)

    1..20
    |> Enum.each(fn x ->
      {:ok, event} = Event.new("Event #{x}")
      Event.set_interval(event, @date1, @date4)
      Event.add_room(event, room1)
    end)

    room_conflicts = room1 |> Room.conflicts |> Enum.count
    assert room_conflicts == 210
  end
end
