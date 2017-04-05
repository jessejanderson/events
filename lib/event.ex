defmodule Events.Event do
  @moduledoc false

  alias Events.{Conflict, Event, Room}
  alias Calendar.DateTime
  alias Calendar.DateTime.{Format, Interval}

  use GenServer

  @enforce_keys [:name]
  defstruct [
    :description,
    :name,
    interval: %Interval{},
    rooms: []
  ]

  # TODO: get dynamic tz from org or local
  @timezone "America/Los_Angeles"

  # +-------+
  # | A P I |
  # +-------+

  def start_link(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def name(event),           do: GenServer.call(event, :name)
  def datetime_start(event), do: GenServer.call(event, :datetime_start)
  def datetime_end(event),   do: GenServer.call(event, :datetime_end)
  def description(event),    do: GenServer.call(event, :description)
  def interval(event),       do: GenServer.call(event, :interval)
  def rooms(event),          do: GenServer.call(event, :rooms)

  def is_overnight(event),   do: GenServer.call(event, :is_overnight)
  def duration(event),       do: GenServer.call(event, :duration)

  def set_name(event, name) do
    GenServer.call(event, {:set_name, name})
  end

  def set_datetime_start(event, datetime_erl) do
    GenServer.call(event, {:set_datetime_start, datetime_erl})
  end

  def set_datetime_end(event, datetime_erl) do
    GenServer.call(event, {:set_datetime_end, datetime_erl})
  end

  def set_description(event, description) do
    GenServer.call(event, {:set_description, description})
  end

  def add_room(event, {:no_return, room}) when is_pid(room) do
    GenServer.call(event, {:no_return, :add_room, room})
  end

  def add_room(event, room) when is_pid(room) do
    GenServer.call(event, {:add_room, room})
  end

  def add_rooms(event, rooms) when is_list(rooms) do
    GenServer.call(event, {:add_rooms, rooms})
  end

  def conflict?(event, %Interval{} = interval) do
    GenServer.call(event, {:conflict, interval})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(name) do
    IO.puts "Starting Event process (name: #{name})"
    {:ok, %Event{name: name}}
  end

  # GET STATE
  # =========

  def handle_call(:name, _from, state) do
    {:reply, state.name, state}
  end

  def handle_call(:datetime_start, _from, state) do
    {:reply, state.interval.from, state}
  end

  def handle_call(:datetime_end, _from, state) do
    {:reply, state.interval.to, state}
  end

  def handle_call(:description, _from, state) do
    {:reply, state.description, state}
  end

  def handle_call(:interval, _from, state) do
    {:reply, state.interval, state}
  end

  def handle_call(:rooms, _from, state) do
    {:reply, state.rooms, state}
  end

  def handle_call(:is_overnight, _from, state) do
    # TODO: check duration for 24+ hours
    {:reply, false, state}
  end

  def handle_call(:duration, _from, state) do
    {:ok, duration_in_seconds, _, :after} =
      DateTime.diff(state.interval.to, state.interval.from)
    {:reply, duration_in_seconds, state}
  end

  # SET STATE
  # =========

  def handle_call({:set_name, name}, _from, state) do
    %Event{state | name: name}
    |> reply_tuple
  end

  def handle_call({:set_description, description}, _from, state) do
    %Event{state | description: description}
    |> reply_tuple
  end

  def handle_call({:set_datetime_start, datetime_erl}, _from, state) do
    datetime_erl
    |> convert_to_cal_datetime
    |> check_for_conflicts(state.interval.to, state.rooms)
    |> add_conflict_to_event
    |> set_datetime_start_for_event(state)
    |> reply_tuple
  end

  def handle_call({:set_datetime_end, datetime_erl}, _from, state) do
    datetime_erl
    |> convert_to_cal_datetime
    |> check_for_conflicts(state.interval.from, state.rooms)
    |> add_conflict_to_event
    |> set_datetime_end_for_event(state)
    |> reply_tuple
  end

  def handle_call({:no_return, :add_room, room}, _from, state) do
    room
    |> add_room_to_event(state)
    |> reply_tuple
  end

  def handle_call({:add_room, room}, _from, state) do
    room
    |> add_self_to_room
    |> add_room_to_event(state)
    |> reply_tuple
  end

  def handle_call({:add_rooms, rooms}, _from, state) do
    rooms
    |> add_self_to_rooms
    |> add_rooms_to_event(state)
    |> reply_tuple
  end

  def handle_call({:conflict, interval}, _from, state) do
    conflict =
      state.interval
      |> Map.from_struct
      |> Map.values
      |> Enum.any?(&(Interval.includes?(interval, &1)))
    {:reply, conflict, state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  defp reply_tuple(state), do: {:reply, state, state}

  defp convert_to_cal_datetime({{_y, _mo, _d}, {_h, _mi, _s}} = datetime) do
    {:ok, cal_datetime} = DateTime.from_erl(datetime, @timezone)
    cal_datetime
  end

  def check_for_conflicts(datetime_start, datetime_end, rooms) do
    # TODO: make conflict/3 work!
    # this is a broken half-baked idea
    # conflicts = Enum.filter(rooms, fn(room) ->
    #   Enum.any?(room.events, fn(event) ->
    #     conflict?(datetime_start, datetime_end, event)
    #   end)
    # end)

    # We'll just say no conflicts for now
    conflicts = []
    {conflicts, datetime_start}
  end

  # def conflict?(datetime_start, datetime_end, event) do
    # TODO: ask Rooms to check their events for given date conflicts
    # Each room will ask its events for start/end datetimes
    # and return event pids that have a conflict

    # Interval.includes?(Event.interval(event), datetime_start)
    # &&
    # Interval.includes?(Event.interval(event), datetime_end)
  # end

  def add_conflict_to_event({[], datetime}), do: datetime
  def add_conflict_to_event({conflicts, datetime}) do
    # TODO: create a %Conflict, add it to Event AND Room
    # %Event{state | conflicts: [conflict | ]}
    datetime
  end

  def set_datetime_start_for_event(datetime, state) do
    new_interval = %Interval{state.interval | from: datetime}
    %Event{state | interval: new_interval}
  end

  def set_datetime_end_for_event(datetime, state) do
    new_interval = %Interval{state.interval | to: datetime}
    %Event{state | interval: new_interval}
  end

  defp add_self_to_room(room) do
    Room.add_event(room, {:no_return, self()})
    room
  end

  defp add_self_to_rooms(rooms) do
    Enum.each(rooms, &add_self_to_room/1)
    rooms
  end

  defp add_room_to_event(room, state) do
    case room in state.rooms do
      true -> state
      false -> Map.update!(state, :rooms, &([room | &1]))
    end
  end

  defp add_rooms_to_event(rooms, state) do
    Enum.reduce(rooms, state, &(add_room_to_event(&1, &2)))
  end

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf(event), do: GenServer.call(event, :wtf)
  def handle_call(:wtf, _from, state), do: reply_tuple(state)

  def puts(event), do: event |> Event.print_to_string |> IO.puts

  def print_to_string(event) do
    name = event |> Event.name
    datetime_start = event
      |> Event.datetime_start
      |> Event.format_datetime_for_print

    datetime_end = event
      |> Event.datetime_end
      |> Event.format_datetime_for_print

    "Event: #{name}\nStart: #{datetime_start}\nEnd: #{datetime_end}"
  end

  def format_datetime_for_print(nil), do: ""
  def format_datetime_for_print(datetime) do
    Format.rfc850(datetime)
  end
end
