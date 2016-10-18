defmodule MessageProcessor do
  import Kernel, except: [send: 2]
  def send_message(pid, target, message) do
    if User.is_welcome?(pid) do
      msg = ":#{User.mask(pid)} PRIVMSG #{target} :#{message}"
      send(target, msg, pid)
    end
  end

  defp send("#" <> channel, msg, user_pid) do
    RoomRegistry.pid_from_channel("#" <> channel)
    |> Room.output
    |> GenServer.cast({:message, msg, user_pid})
  end

  defp send(nick, msg, _user_pid) do
    UserRegistry.pid_from_nick(nick)
    |> User.output
    |> GenServer.cast({:message, msg})
  end
end
