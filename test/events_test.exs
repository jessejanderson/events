defmodule EventsTest do
  use ExUnit.Case
  doctest Events

  alias Events.{Event, EventsList, Room, RoomsList}

  @event_name "My First Event"
  @room_name "Room 101"
  @date1 {{2020, 1, 1}, {1, 0, 0}}
  @date2 {{2020, 1, 1}, {2, 0, 0}}
  @date3 {{2020, 1, 1}, {3, 0, 0}}
  @date4 {{2020, 1, 1}, {4, 0, 0}}
  @date5 {{2020, 1, 1}, {5, 0, 0}}
  @date6 {{2020, 1, 1}, {6, 0, 0}}

  setup do
    EventsList.start_link
    RoomsList.start_link
    {:ok, event1} = Event.start_link(@event_name)
    {:ok, room1} = Room.start_link(@room_name)
    {:ok, event1: event1, room1: room1}
  end

  test "Add a room to an event", %{event1: event1, room1: room1} do
    Event.set_interval(event1, @date1, @date2)
    Event.add_room(event1, room1)

    assert event1 in EventsList.events
    assert event1 in Room.events(room1)

    assert room1 in RoomsList.rooms
    assert room1 in Event.rooms(event1)
  end

  test "Add a room to 2 events and create a conflict",
  %{event1: event1, room1: room1} do
    {:ok, event2} = Event.start_link("My Second Event")
    Event.set_interval(event1, @date1, @date3)
    Event.set_interval(event2, @date2, @date4)

    Event.add_room(event1, room1)
    Event.add_room(event2, room1)

    # conflict_events =
    #   room1
    #   |> Room.conflicts
    #   |> hd
    #   |> Map.get(:events)

    # assert event1 in conflict_events
    # assert event2 in conflict_events
  end


  test "generate 50 events and add the same room to create conflicts",
  %{room1: room1} do
    {:ok, room2} = Room.start_link("Room 202")
    {:ok, room3} = Room.start_link("Room 303")
    {:ok, room4} = Room.start_link("Room 404")

    rooms = [room1, room2, room3, room4]
    dates = [@date1, @date2, @date3, @date4, @date5, @date6]

    events_time =
      :timer.tc(fn ->
        1..50
        |> Enum.each(fn x ->
          {:ok, event} = Event.start_link("Event #{x}")
        end)
      end)

    intervals_time =
      :timer.tc(fn ->
        EventsList.events
        |> Enum.each(fn x ->
          # Event.set_interval(x, Enum.random(dates), Enum.random(dates))
          Event.set_interval(x, @date1, @date4)
        end)
      end)

    conflicts_time =
      :timer.tc(fn ->
        EventsList.events
        |> Enum.each(fn x ->
          # Event.add_room(x, Enum.random(rooms))
          Event.add_room(x, room1)
        end)
      end)

    IO.puts "Seconds to create 50 events:"
    IO.puts events_time |> elem(0) |> Kernel./(1_000_000)
    IO.puts "Seconds to set intervals for those events:"
    IO.puts intervals_time |> elem(0) |> Kernel./(1_000_000)
    IO.puts "Seconds to add a room to all events and create 1,275 conflicts:"
    IO.puts conflicts_time |> elem(0) |> Kernel./(1_000_000)
    total_time = elem(events_time, 0) + elem(intervals_time, 0) + elem(conflicts_time, 0)
    IO.puts "TOTAL TIME: #{total_time |> Kernel./(1_000_000)} seconds"

    room_conflicts = room1 |> Room.conflicts |> Enum.count
    |> IO.puts

    # triangular number of 50 - 1
    assert ^room_conflicts = 1275

    rooms
    |> Enum.map(fn room -> room |> Room.conflicts |> Enum.count end)
    |> Enum.each(fn count -> IO.puts("== #{count} conflicts") end)

    new_event_time =
      :timer.tc(fn ->
        {:ok, new_event} = Event.start_link("New Event")
        Event.set_interval(new_event, @date1, @date6)
        Event.add_room(new_event, room1)
        Event.add_room(new_event, room2)
        Event.add_room(new_event, room3)
        Event.add_room(new_event, room4)
        end)
    IO.puts "Total Time for new event:"
    IO.puts new_event_time |> elem(0) |> Kernel./(1_000_000)
    new_room_conflicts = room1 |> Room.conflicts |> Enum.count
    |> IO.puts
  end
end
