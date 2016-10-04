defmodule MessageProcessor do
  def send_message(_pid, target, message) do
    recipient = room_or_user(target)
    send(recipient, message)
  end

  defp room_or_user(target) do
    _pid = UserRegistry.pid_from_nick(target) # for now, handle rooms later
    # actually return another process not an agent pid, figured out from room/user agent pid
  end

end