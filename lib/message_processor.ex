defmodule MessageProcessor do
  def send_message(pid, target, message) do
    if User.is_welcome?(pid) do
      send_message_to(target, pid, message)
    end
  end

  defp send_message_to("#" <> channel, pid, message) do
    RoomRegistry.pid_from_channel(channel) # for now, handle rooms later
    |> Room.output
  end

  defp send_message_to(nick, pid, message) do
    UserRegistry.pid_from_nick(nick) # for now, handle rooms later
    |> User.output
    |> GenServer.cast({:message, ":#{User.mask(pid)} PRIVMSG #{nick} :#{message}"})
  end
end
