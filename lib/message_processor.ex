defmodule MessageProcessor do
  def send_message(pid, target, message) do
    if User.is_welcome?(pid) do
      msg = "#{Msgformat.prefix} :#{User.mask(pid)} PRIVMSG #{target} :#{message}"
      output_for(target)
      |> GenServer.cast({:message, msg})
    end
  end

  defp output_for("#" <> channel) do
    RoomRegistry.pid_from_channel("#" <> channel)
    |> Room.output
  end

  defp output_for(nick) do
    UserRegistry.pid_from_nick(nick)
    |> User.output
  end
end
