defmodule Events do
  @moduledoc """
  Documentation for Events.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Events.hello
      :world

  """
  def hello do
    :world
  end

  def test(orgs, events, rooms) do
    range = 1..orgs
    Enum.each(range, &Events.Org.new/1)
    1..events |> Enum.each(fn n ->
      Enum.each(range, &(Events.Event.new(&1, "Event #{n}")))
    end)
    1..rooms |> Enum.each(fn n ->
      Enum.each(range, &(Events.Room.new(&1, "Room #{n}0#{n}")))
    end)
  end
end
