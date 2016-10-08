defmodule RoomOutput do
  require Logger
  use GenServer

  def start(agent_pid) do
    {:ok, pid} = GenServer.start(__MODULE__, agent_pid, [name: String.to_atom("RoomOutput#{Room.data(agent_pid).channel}")])
    Room.set_output(agent_pid, pid)
  end

  def message(pid, msg) do
    GenServer.cast(pid, {:message, msg})
  end

  def handle_cast({:message, msg}, room_pid) do
    Room.users(room_pid)
    |> Enum.each(fn user_pid ->
      User.output(user_pid)
      |> GenServer.cast({:message, msg})
    end)

    {:noreply, room_pid}
  end
end

