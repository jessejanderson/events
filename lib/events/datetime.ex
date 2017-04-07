defmodule Events.DateTime do
  @moduledoc false

  alias Calendar.DateTime, as: CalDT
  alias DateTime, as: DT

  def create_interval(start_erl, end_erl, timezone) do
    {:ok, start_dt} = CalDT.from_erl(start_erl, timezone)
    {:ok, end_dt}   = CalDT.from_erl(end_erl, timezone)
    create_interval(start_dt, end_dt)
  end

  def create_interval(%DT{} = start_dt, %DT{} = end_dt) do
    %CalDT.Interval{from: start_dt, to: end_dt}
  end

  def find_interval_overlap(intervals) when is_list(intervals) do
    {from_dts, to_dts} = separate_start_and_end_datetimes(intervals)

    first_end = to_dts |> sort_datetimes |> hd
    last_start = from_dts |> sort_datetimes |> tl

    %CalDT.Interval{from: last_start, to: first_end}
  end

  def separate_start_and_end_datetimes(intervals) do
    intervals
    |> Enum.reduce({[], []}, fn(x, acc) ->
      {[x.from | elem(acc, 0)], [x.to | elem(acc, 1)]}
    end)
  end

  def sort_datetimes(datetimes) when is_list(datetimes) do
    Enum.sort_by(datetimes, &CalDT.Format.unix/1)
  end

end
