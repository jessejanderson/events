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
    assert [] = Room.events(state[:room])

    {:ok, event} = Events.Event.start_link("Event 1")
    Room.add_event(state[:room], event)
    assert [^event] = Room.events(state[:room])
  end

  test "Add multiple events", state do
    assert [] = Room.events(state[:room])

    {:ok, event1} = Events.Event.start_link("Event 1")
    {:ok, event2} = Events.Event.start_link("Event 2")
    Room.add_event(state[:room], [event1, event2])
    assert [^event1, ^event2] = Room.events(state[:room])
  end

  test "Add an approver", state do
    assert [] = Room.approvers(state[:room])

    Room.add_approver(state[:room], "Jack")
    assert ["Jack"] = Room.approvers(state[:room])
  end

  test "Add multiple approvers", state do
    assert [] = Room.approvers(state[:room])

    Room.add_approver(state[:room], ["Jack", "Kate"])
    assert ["Jack", "Kate"] = Room.approvers(state[:room])
  end

end
