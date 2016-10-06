defmodule MessageProcessor do
  def send_message(pid, target, message) do
    if User.is_welcome?(pid) do
      sender_mask = User.mask(pid)
      recipient = get_writers(target)
      msg = ":#{sender_mask} PRIVMSG #{target} :#{message}"
      GenServer.cast(recipient, {:message, msg})
    end
  end

  defp get_writers("#" <> roomname) do
  end
  defp get_writers(nick) do
    pid = UserRegistry.pid_from_nick(nick) # for now, handle rooms later
    User.output(pid)
  end

end
