defmodule Events.Event do
  @enforce_keys [:name]
  defstruct [:datetime_start, :datetime_end, :name, :description, isOvernight: false, rooms: []]

  alias Events.Event

  # Assumed for now
  @timezone "America/Los_Angeles"

  def start_link(name) do
    Agent.start_link(fn -> %Event{name: name} end)
  end

  # +-------------------+
  # | GET CURRENT STATE |
  # +-------------------+

  def name(event), do:           Agent.get(event, fn state -> state.name end)
  def datetime_start(event), do: Agent.get(event, fn state -> state.datetime_start end)
  def datetime_end(event), do:   Agent.get(event, fn state -> state.datetime_end end)

  def set_name(event, name), do: Agent.update(event, &(%Event{&1 | name: name}))

  # +---------------+
  # | SET DATETIMES |
  # +---------------+

  def set_datetime_start(event, datetime), do: set_datetime(event, :start, datetime)
  def set_datetime_end(event, datetime),   do: set_datetime(event, :end, datetime)

  defp set_datetime(event, :start, %DateTime{} = datetime) do
    Agent.update(event, &(%Event{&1 | datetime_start: datetime}))
  end

  defp set_datetime(event, :end, %DateTime{} = datetime) do
    Agent.update(event, &(%Event{&1 | datetime_end: datetime}))
  end

  defp set_datetime(event, start_or_end, {{_y, _mo, _d}, {_h, _mi, _s}} = datetime_erl) do
    {:ok, datetime} = Calendar.DateTime.from_erl(datetime_erl, @timezone)
    set_datetime(event, start_or_end, datetime)
  end

  # +----------------------+
  # | CONVENIENCE PRINTING |
  # +----------------------+

  def wtf(event), do: Agent.get(event, &(&1))

  def puts(event), do: Event.to_string(event) |> IO.puts

  def to_string(event) do
    name = event |> Event.name
    datetime_start = event |> Event.datetime_start |> Event.format_datetime_for_print
    datetime_end = event |> Event.datetime_end |> Event.format_datetime_for_print
    "Event: #{name}\nStart: #{datetime_start}\nEnd: #{datetime_end}"
  end

  def format_datetime_for_print(nil), do: ""
  def format_datetime_for_print(datetime), do: Calendar.DateTime.Format.rfc850(datetime)
end
