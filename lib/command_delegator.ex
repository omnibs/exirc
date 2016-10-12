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
    # REQUEST:
    # WHO #somechan %chtsunfra,152
    #               ^^^^^^^^^^^^^^
    # i thiiiink this last part is what causes the nonstandard response below

    # RESPONSE:
    # :asimov.freenode.net 354 joining_user_nickname 152 #somechan ~Juliano 207.251.103.46 asimov.freenode.net joining_user_nickname H 0 :realname
    # :asimov.freenode.net 354 joining_user_nickname 152 #somechan ChanServ services. services. ChanServ H@ 0 :Channel Services
    # :asimov.freenode.net 354 joining_user_nickname 152 #somechan ~Juliano 207.251.103.46 wilhelm.freenode.net omnibs H 0 :realname
    #                      ^^^
    # WHO response, this format is not in the RFC ._. see here https://www.alien.net.au/irc/irc2numerics.html
    # :asimov.freenode.net 315 joining_user_nickname #somechan :End of /WHO list.
    Logger.info("WHO command, #{who_command}, TODO")
  end

  def process("PING " <> _host, user_pid) do
    User.output(user_pid)
    |> GenServer.cast({:message, "PONG #{Msgformat.host}"})
  end

  def process("MODE " <> room) do
    # :asimov.freenode.net 324 joining_user_nickname #somechan +cnt
    # :asimov.freenode.net 329 joining_user_nickname #somechan 1345057755
    #                      ^^^ 
    # creation time according to https://www.alien.net.au/irc/irc2numerics.html (this is not in the rfc ._.)
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
