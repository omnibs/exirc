defmodule CommandDelegator do
  require Logger

  def process("NICK " <> nick, pid) do
    NickChangeProcessor.change_nick(pid, nick)
  end

  def process("USER :" <> userdata, pid) do
    User.set_info(pid, userdata)
  end

  def process("JOIN " <> room, pid) do
    RoomProcessor.handle(room, pid, :join)
  end

  def process("PART " <> room, pid) do
    RoomProcessor.handle(room, pid, :part)
  end

  def process("PRIVMSG " <> target_message, pid) do
    [target, message] = split_message(target_message)
    MessageProcessor.send_message(pid, target, message)
  end

  def process(unknown_msg, _pid) do
    Logger.info "unknown_msg: #{inspect(unknown_msg)}"
  end

  defp split_message(message) do
    [part_one, part_two] = String.split(message, " ", parts: 2)
    [part_one, clean(part_two)]
  end

  defp clean(":" <> clean_content) do
    clean_content
  end
end
