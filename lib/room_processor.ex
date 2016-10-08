defmodule RoomProcessor do
  def join(room, user_pid) do
    RoomRegistry.pid_from_channel(room)
    |> Room.add_user(user_pid)
  end

  def part(room, user_pid) do
    RoomRegistry.pid_from_channel(room)
    |> Room.remove_user(user_pid)
  end

end
