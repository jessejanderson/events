defmodule Events.Helpers do
  @moduledoc false

  def add_pid_if_unique(state, pid) when is_list(state) do
    case pid in state do
      true  -> {:error, "this pid already exists"}
      false -> {:ok, [pid | state]}
    end
  end
end
