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
  #  A        [-----------]
  #  B  [-----------]
  #  C        [-----------------]
  #  D              [-----------]


  #  [Q2]
  #  What's the .conflicts? path?

  #  1. Adjust interval in Event
  #  2. Event asks each room if it has conflicts with new interval
  #  3. Each room asks each event if it has conflicts with new interval
  #  4. Each event replies with true/false
  #  5. Each room take reply, return {room_pid, [event_pids]} if .any? are true
  #  6. Event.conflicts = [%Conflict{room: room, events: [...]}, ...]

  #  EXAMPLE:
  # [%Conflict{room: PID<1.1>, events: [PID<1.2>, PID<1.3>]}, %Conflict{...}]
  # actually...
  # [PID<3.1>, PID<3.2>] #each pid points to a process with %Conflict{} state

  # 1. Event.set_datetime_start(event, datetime_erl)
  # 2. Event -> Room.event_conflicts(room, interval)
  # 3. Room -> Event.conflicts(event, interval)


  #  [Q3]
  #  Where do conflicts live?

  #  Rooms have a list of all associated events
  #    and can return a list of conflicts by checking all events
  #  Events have a list of all associated rooms
  #    doesn't have conflicts
  #    but can find them by asking all rooms
  #  Ultimately conflicts live as floating processes
  #    that are referenced as conflicts within Rooms.conflicts
  #    and need to die when a conflict goes away

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