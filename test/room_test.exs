defmodule RoomTest do
  use ExUnit.Case
  alias Events.{Event, EventsList, Room, RoomsList}

  doctest Room

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}
  # @timezone "America/Los_Angeles"

  setup do
    EventsList.start_link
    RoomsList.start_link
    {:ok, room} = Room.start_link(@room_name)
    {:ok, room: room}
  end

  test "Set name for room", %{room: room} do
    assert @room_name = Room.name(room)
    Room.set_name room, "New Name"
    assert "New Name" = Room.name(room)
  end

  test "Add room to event", %{room: room} do
    {:ok, event} = Event.start_link(@event_name)
    Event.set_interval event, @date1, @date2
    Event.add_room event, room
    assert [^event] = Room.events(room)
  end

  test "Create conflict for room", %{room: room} do
    {:ok, event1} = Event.start_link("My First Event")
    {:ok, event2} = Event.start_link("My Second Event")
    Event.set_interval event1, @date1, @date2
    Event.set_interval event2, @date1, @date2
    Event.add_room event1, room
    assert [] = Room.conflicts(room)
    Event.add_room event2, room
    assert event2 in Room.events(room)
    conflicts = Room.conflicts room
    assert event1 in hd(conflicts).events
    assert event2 in hd(conflicts).events
  end

end
