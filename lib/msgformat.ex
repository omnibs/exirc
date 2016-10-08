defmodule Msgformat do
  @version "16.09.03"
  @rpl_welcome "001"
  @rpl_yourhost "002"
  @rpl_created "003"
  @rpl_myinfo "004"
  @err_nicknameinuse "433"
  @server_host Application.get_env(:exircd, :server_host) || "localhost"
  def new(msg_id, nick, data) do
    ":#{@server_host} #{msg_id} #{nick || "*"} #{data}"
  end

  def welcome(nick) do
    [
      new(@rpl_welcome, nick, ":Welcome to #{@server_host}"),
      new(@rpl_yourhost, nick, ":Your host is exirc running version #{@version}"),
      new(@rpl_created, nick, ":This server was created 2016-09-03"),
      new(@rpl_myinfo, nick, "exirc #{@version} oiv r\"")
    ]
  end

  def nick_in_use(old_nick, new_nick) do
    new(@err_nicknameinuse, old_nick, "#{new_nick} :Nickname is already in use.")
  end

  def nick_changed(mask, new_nick) do
    ":#{mask} NICK :#{new_nick}"
  end
end
