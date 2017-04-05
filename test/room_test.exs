defmodule RoomTest do
  use ExUnit.Case
  alias Events.Room

  doctest Room

  @name "My Room"

  setup do
    {:ok, room} = Room.start_link(@name)
    {:ok, room: room}
  end

  test "Room returns name", state do
    assert @name = Room.name(state[:room])
  end

  test "Change room name", state do
    Room.set_name(state[:room], "New Room Name")
    assert "New Room Name" = Room.name(state[:room])
  end

  test "Add an event", state do
    room = state[:room]
    assert [] = Room.events(room)

    {:ok, event} = Events.Event.start_link("Event 1")
    Room.add_event(room, event)
    assert [^event] = Room.events(room)
  end

  test "Add multiple events", state do
    room = state[:room]
    assert [] = Room.events(room)

    {:ok, event1} = Events.Event.start_link("Event 1")
    {:ok, event2} = Events.Event.start_link("Event 2")
    Room.add_events(room, [event1, event2])

    assert Enum.member?(Room.events(room), event1)
    assert Enum.member?(Room.events(room), event2)


    {:ok, event3} = Events.Event.start_link("Event 3")
    refute Enum.member?(Room.events(room), event3)
  end

  test "Add a conflict", state do
    room = state[:room]
    assert [] = Room.conflicts(room)

    {:ok, conflict} = Events.Conflict.start_link(room)
    Room.add_conflict(room, conflict)

    assert Enum.member?(Room.conflicts(room), conflict)
  end

  test "Add multiple conflicts", state do
    room = state[:room]
    assert [] = Room.conflicts(room)

    {:ok, conflict1} = Events.Conflict.start_link(room)
    {:ok, conflict2} = Events.Conflict.start_link(room)
    {:ok, conflict3} = Events.Conflict.start_link(room)

    Room.add_conflicts(room, [conflict1, conflict2])

    assert Enum.member?(Room.conflicts(room), conflict1)
    assert Enum.member?(Room.conflicts(room), conflict2)
    refute Enum.member?(Room.conflicts(room), conflict3)
  end

  # test "Add an approver", state do
  #   room = state[:room]
  #   assert [] = Room.approvers(room)

  #   Room.add_approver(room, "Jack")
  #   assert ["Jack"] = Room.approvers(room)
  # end

  # test "Add multiple approvers", state do
  #   room = state[:room]
  #   assert [] = Room.approvers(room)

  #   Room.add_approvers(room, ["Jack", "Kate"])
  #   assert ["Jack", "Kate"] = Room.approvers(room)
  # end

end
