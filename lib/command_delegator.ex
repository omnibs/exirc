defmodule CommandDelegator do
  require Logger

  def process("NICK " <> nick, user_pid) do
    NickChangeProcessor.change_nick(user_pid, nick)
  end

  def process("USER " <> userdata, user_pid) do
    user = User.data(user_pid)
    User.set_info(user_pid, userdata)

    # TODO: move this out?
    if user.nick && !user.name do
      out_pid = User.output(user_pid)
      Msgformat.welcome(user.nick)
      |> Enum.each(fn msg ->
        SocketWriteClient.message(out_pid, msg)
      end)
    end
  end

  def process("LIST" <> _, user_pid) do
    ListProcessor.list(user_pid)
  end

  def process("JOIN " <> room, user_pid) do
    RoomProcessor.join(room, user_pid)
  end

  def process("PART " <> room, user_pid) do
    RoomProcessor.part(room, user_pid)
  end

  def process("PRIVMSG " <> target_message, user_pid) do
    [target, message] = split_message(target_message)
    MessageProcessor.send_message(user_pid, target, message)
  end

  def process("WHO" <> who_command, user_pid) do
    Logger.info("WHO command, #{who_command}, TODO")
  end

  def process("PING " <> _host, user_pid) do
    User.output(user_pid)
    |> GenServer.cast({:message, "PONG #{Msgformat.host}"})
  end

  def process(unknown_msg, _user_pid) do
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
