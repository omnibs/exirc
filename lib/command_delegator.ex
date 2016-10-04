defmodule CommandDelegator do
  require Logger

  def process("NICK " <> nick, port) do
    pid = get_pid(port)
    NickChangeProcessor.change_nick(pid, nick)
  end

  def process("USER " <> userdata, port) do
    User.set_info(get_pid(port), clean(userdata))
  end

  def process("JOIN " <> room, port) do
    RoomProcessor.handle(clean(room), get_pid(port), :join)
  end

  def process("PART " <> room, port) do
    RoomProcessor.handle(clean(room), get_pid(port), :part)
  end

  def process("PRIVMSG " <> target_message, port) do
    [target, message] = split_message(target_message)
    MessageProcessor.send_message(get_pid(port), target, message)
  end

  def process(unknown_msg, _port) do
    Logger.info "unknown_msg: #{inspect(unknown_msg)}"
  end

  defp split_message(message) do
    [part_one, part_two] = String.split(message, " ", parts: 2)
    [part_one, clean(part_two)]
  end

  defp clean(dirty_content) do
    ":" <> clean_content = dirty_content
    clean_content
  end

  defp get_pid(port), do: UserRegistry.pid_from_port(port)
end
