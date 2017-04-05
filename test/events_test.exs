defmodule EventsTest do
  use ExUnit.Case
  doctest Events

  alias Events.{Event, Room, Rooms}

  @event_name "My Event"
  @room_name "Room 101"

  # setup do
  #   {:ok, event} = Event.start_link(@name)
  #   {:ok, event: event}
  # end

  test "Create a new event and add a room" do
    Rooms.start_link
    {:ok, event} = Event.start_link(@event_name)
    {:ok, room1} = Room.start_link(@room_name)
    Event.add_room(event, room1)

    assert [^room1] = Event.list_rooms(event)
    assert [^event] = Room.list_events(room1)
  end
end
