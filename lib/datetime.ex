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
end
