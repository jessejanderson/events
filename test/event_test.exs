defmodule EventTest do
  use ExUnit.Case
  alias Events.Event

  doctest Event

  @name "My Event"

  setup do
    {:ok, event} = Event.start_link(@name)
    {:ok, event: event}
  end

  test "Event returns name", state do
    assert @name = Event.name(state[:event])
  end

  test "Change event name", state do
    Event.set_name(state[:event], "New Event Name")
    assert "New Event Name" = Event.name(state[:event])
  end

  test "Add event description", state do
    Event.set_description(state[:event], "This is my event description.")
    assert "This is my event description." = Event.description(state[:event])
  end

  test "Add datetime_start", state do
    event = state[:event]
    refute Event.datetime_start(event)

    Event.set_datetime_start(state[:event], {{2020, 5, 30}, {20, 0, 0}})
    datetime = Event.datetime_start(event)

    assert 2020 = datetime.year
    assert 5    = datetime.month
    assert 30   = datetime.day
    assert 20   = datetime.hour
    assert 0    = datetime.minute
    assert 0    = datetime.second
  end

  test "Add datetime_end", state do
    event = state[:event]
    refute Event.datetime_end(event)

    Event.set_datetime_end(event, {{2020, 5, 30}, {21, 30, 0}})
    datetime = Event.datetime_end(event)

    assert 2020 = datetime.year
    assert 5    = datetime.month
    assert 30   = datetime.day
    assert 21   = datetime.hour
    assert 30   = datetime.minute
    assert 0    = datetime.second
  end

  test "Update is_overnight to true", state do
    event = state[:event]
    refute Event.is_overnight(event)

    Event.set_is_overnight(event, true)
    assert true = Event.is_overnight(event)
  end

  test "Add a room", state do
    event = state[:event]
    assert [] = Event.rooms(event)

    {:ok, room} = Events.Room.start_link("Room 101")
    Event.add_room(event, room)
    assert [^room] = Event.rooms(event)

    # Make sure the Room has the event too
    assert [event] = Events.Room.events(room)
  end

  test "Add multiple rooms", state do
    event = state[:event]
    assert [] = Event.rooms(event)

    {:ok, room1} = Events.Room.start_link("Room 101")
    {:ok, room2} = Events.Room.start_link("Room 202")
    Event.add_rooms(event, [room1, room2])

    assert Enum.member?(Event.rooms(event), room1)
    assert Enum.member?(Event.rooms(event), room2)

    {:ok, room3} = Events.Room.start_link("Unused Room")
    refute Enum.member?(Event.rooms(event), room3)
  end

  # test "Check for identical start/end time conflicts", state do
  #   event1 = state[:event]
  #   {:ok, event2} = Event.start_link("My Second Event")

  #   {:ok, room1} = Events.Room.start_link("Room 101")
  #   {:ok, room2} = Events.Room.start_link("Room 202")
  #   {:ok, room3} = Events.Room.start_link("Room 303")

  #   assert Event.conflicts(event1) = []
  #   assert Event.conflicts(event2) = []

  #   Event.add_room(event1, [room1, room2])
  #   Event.add_room(event2, [room1, room3])

  #   assert [^room1, ^room2] = Event.rooms(event1)
  #   assert [^room1, ^room3] = Event.rooms(event2)

  #   Event.set_datetime_start(event1, {{2017, 5, 30}, {13, 0, 0}})
  #   Event.set_datetime_end(event1, {{2017, 5, 30}, {15, 0, 0}})
  #   Event.set_datetime_start(event2, {{2017, 5, 30}, {13, 0, 0}})
  #   Event.set_datetime_end(event2, {{2017, 5, 30}, {15, 0, 0}})

  #   assert Event.conflicts(event1) = [event2]
  #   assert Event.conflicts(event2) = [event1]
  # end

end
