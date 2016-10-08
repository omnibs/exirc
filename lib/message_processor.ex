defmodule MessageProcessor do
  def send_message(pid, target, message) do
    if User.is_welcome?(pid) do
      send_message_to(target, pid, message)
    end
  end

  defp send_message_to("#" <> channel, pid, message) do
    RoomRegistry.pid_from_channel("#" <> channel)
    |> Room.output
    |> GenServer.cast({:message, ":#{User.mask(pid)} PRIVMSG ##{channel} :#{message}"})
  end

  defp send_message_to(nick, pid, message) do
    UserRegistry.pid_from_nick(nick)
    |> User.output
    |> GenServer.cast({:message, ":#{User.mask(pid)} PRIVMSG #{nick} :#{message}"})
  end
end
