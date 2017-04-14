defmodule EventsTest do
  use ExUnit.Case

  doctest Events

  alias Events.{Event, Org, Room, RoomList}

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}
  @date3 {{2020, 1, 1}, {3, 0, 0}}
  @date4 {{2020, 1, 1}, {4, 0, 0}}
  # @date5 {{2020, 1, 1}, {5, 0, 0}}
  # @date6 {{2020, 1, 1}, {6, 0, 0}}

  setup do
    org_id = Enum.random(1..9999)
    room_id = Enum.random(1..9999)
    event_id = Enum.random(1..9999)

    {:ok, _org} = Org.new(org_id)
    {:ok, event} = Event.new(org_id, event_id, @event_name)
    {:ok, room} = Room.new(org_id, room_id, @room_name)
    {:ok, event: event, room: room, org_id: org_id}
  end

  test "Add a room to an event", %{event: event, room: room, org_id: org_id} do
    Event.set_interval(event, @date1, @date2)
    Event.add_room(event, room)

    assert event in Room.events(room)

    assert room in RoomList.rooms(org_id)
    assert room in Event.rooms(event)
  end

  @tag :pending
  test "Add a room to 2 events and create a conflict",
  %{event: event, room: room, org_id: org_id} do
    {:ok, event2} = Event.new(org_id, 10_001, "My Second Event")
    Event.set_interval(event, @date1, @date3)
    Event.set_interval(event2, @date2, @date4)

    Event.add_room(event, room)
    Event.add_room(event2, room)

    conflict_events =
      room |> Room.conflicts |> hd |> Map.get(:events)

    assert event in conflict_events
    assert event2 in conflict_events
  end


  @tag :pending
  test "generate 20 events and add the same room to create conflicts",
  %{event: event, room: room, org_id: org_id} do
    Event.set_interval(event, @date1, @date4)
    Event.add_room(event, room)

    1..20
    |> Enum.each(fn x ->
      {:ok, new_event} = Event.new(org_id, 10_000 + x, "Event #{x}")
      Event.set_interval(new_event, @date1, @date4)
      Event.add_room(new_event, room)
    end)

    room_conflicts = room |> Room.conflicts |> Enum.count
    assert room_conflicts == 210
  end
end
