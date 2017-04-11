defmodule Events do
  @moduledoc """
  Documentation for Events.
  """

  def test(orgs, events, rooms) do
    date1 = {{2020, 1, 1}, {1, 0, 0}}
    date2 = {{2020, 1, 1}, {2, 0, 0}}

    Enum.each(1..orgs, &Events.Org.new/1)

    1..orgs
    |> Enum.each(fn org ->
      Enum.each(1..rooms, fn room ->
        Events.Room.new(org, room, "Room #{room}0#{room}")
      end)
    end)

    1..orgs
    |> Enum.each(fn org ->
      Enum.each(1..events, fn event ->
        {:ok, new_event} = Events.Event.new(org, event, "Event #{event}")
        Events.Event.set_interval(new_event, date1, date2)

        org
        |> Events.RoomList.rooms
        |> Enum.each(fn room -> Events.Event.add_room(new_event, room) end)

        # room = org |> Events.RoomList.rooms |> hd
        # Events.Event.add_room(new_event, room)
      end)
    end)
  end
end
