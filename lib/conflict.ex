defmodule Events.Conflict do
  @moduledoc false

  alias Events.{Conflict, Event, Room}
  alias Calendar.DateTime.Interval

  @enforce_keys [:room]
  defstruct [
    :room,
    interval: %Interval{},
    events: [],
  ]

  # +-------------------------------------+
  # | IMPORTANT QUESTIONS ABOUT CONFLICTS |
  # +-------------------------------------+

  #  [Q1]
  #  What does this return?

  #     1     2     3     4     5
  #  A  [-----------]
  #  B        [-----------------]
  #  C        [-----------]


  #  [Q2]
  #  What's the .conflicts? path?

  #  1. Adjust interval in Event
  #  2. Event asks each room if it has conflicts with new interval
  #  3. Each room asks each event if it has conflicts with new interval
  #  4. Each event replies with true/false
  #  5. Each room take reply, return {room_pid, [event_pids]} if .any? are true
  #  6. Event.conflicts = [{room, [events]}, {room2, [events2]}]

  #  EXAMPLE:
  # conflicts: [{PID<1.1>, [PID<1.2>, PID<1.3>]}, {PID<2.1>, [PID<2.2>]}]


  # +-------+
  # | A P I |
  # +-------+

  def start_link(room) when is_pid(room) do
    GenServer.start_link(__MODULE__, room)
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(room) do
    {:ok, %Conflict{room: room}}
  end

end
