defmodule RoomOutput do
  require Logger
  use GenServer

  def start(room_agent_pid) do
    {:ok, room_pid} = GenServer.start(__MODULE__,room_agent_pid)
    Room.set_output(room_agent_pid, room_pid)
  end

  def message(pid, msg) do
    GenServer.cast(pid, {:message, msg})
  end

  def handle_cast({:message, msg, sender_pid}, room_pid) do
    Room.users(room_pid)
    |> Enum.filter(fn user_pid -> user_pid != sender_pid end)
    |> Enum.each(fn user_pid ->
      User.output(user_pid)
      |> GenServer.cast({:message, msg})
    end)

    {:noreply, room_pid}
  end
end

