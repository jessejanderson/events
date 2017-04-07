defmodule Events.RoomsList do
  @moduledoc """
    Holds all the rooms
  """

  alias Events.Helpers

  use GenServer

  @name __MODULE__

  # +-------+
  # | A P I |
  # +-------+

  def start_link(rooms \\ []) when is_list(rooms) do
    # IO.puts "===== ROOMS: #{inspect self()} :: Starting"
    GenServer.start_link(__MODULE__, rooms, name: @name)
  end

  def rooms do
    GenServer.call(@name, :rooms)
  end

  def add_room(room) when is_pid(room) do
    GenServer.call(@name, {:add_room, room})
  end

  def remove_room(room) when is_pid(room) do
    GenServer.call(@name, {:remove_room, room})
  end

  # +-------------------+
  # | C A L L B A C K S |
  # +-------------------+

  def init(rooms) do
    # IO.puts "- - - ROOMS: #{inspect self()} :: Initializing"
    {:ok, rooms}
  end

  def handle_call(:rooms, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_room, room}, _from, state) do
    {:ok, new_state} = Helpers.add_pid_if_unique(state, room)
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_room, room}, _from, state) do
    new_state = List.delete(state, room)
    {:reply, :ok, new_state}
  end

  # +---------------+
  # | P R I V A T E |
  # +---------------+

  # +-----------------------+
  # | C O N V E N I E N C E |
  # +-----------------------+

  def wtf, do: GenServer.call(@name, :wtf)
  def handle_call(:wtf, _from, state), do: {:reply, state, state}

end
