defmodule EventTest do
  use ExUnit.Case
  alias Events.{Event, Room}
  alias Events.Event.Schedule

  doctest Event

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}
  @timezone "America/Los_Angeles"

  setup do
    {:ok, event} = Event.new(@event_name)
    {:ok, event: event}
  end

  test "Set interval for event", %{event: event} do
    refute Event.interval(event).from
    refute Event.interval(event).to
    Event.set_interval event, @date1, @date2
    dt1 = Calendar.DateTime.from_erl!(@date1, @timezone)
    dt2 = Calendar.DateTime.from_erl!(@date2, @timezone)
    assert ^dt1 = Event.interval(event).from
    assert ^dt2 = Event.interval(event).to
  end

  test "Set description for event", %{event: event} do
    refute Event.description(event)
    Event.set_description event, "Lorem ipsum"
    assert "Lorem ipsum" = Event.description(event)
  end

  test "Set name for event", %{event: event} do
    assert @event_name = Event.name(event)
    Event.set_name event, "New Name"
    assert "New Name" = Event.name(event)
  end

  test "Add room to event", %{event: event} do
    assert [] = Event.rooms(event)
    {:ok, room} = Room.new(@room_name)
    Event.add_room event, room
    assert [^room] = Event.rooms(event)
  end

  test "Remove room from event", %{event: event} do
    assert {:ok, room} = Room.new(@room_name)
    Event.add_room event, room
    assert [^room] = Event.rooms(event)
    Event.remove_room event, room
    assert [] = Event.rooms(event)
  end

  test "Set daily schedule for event", %{event: event} do
    assert :one_time = Event.schedule(event).type
    schedule = %Schedule{type: :daily}
    Event.set_schedule event, schedule
    assert :daily = Event.schedule(event).type
  end

  # test "Add same room twice to event", %{event: event} do
  #   # Ensure Supervisor restarts event
  #   assert [] = Event.rooms(event)
  #   {:ok, room} = Room.start_link(@room_name)
  #   Event.add_room event, room
  #   assert [^room] = Event.rooms(event)
  #   Event.add_room event, room
  #   assert [^room] = Event.rooms(event)
  # end

  test "Add 2 rooms to event", %{event: event} do
    assert [] = Event.rooms(event)
    assert {:ok, room1} = Room.new(@room_name)
    Event.add_room event, room1
    assert [^room1] = Event.rooms(event)
    assert {:ok, room2} = Room.new("Room 202")
    Event.add_room event, room2
    assert room2 in Event.rooms(event)
  end

end
