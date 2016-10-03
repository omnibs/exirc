defmodule Msgformat do
  @version "16.09.03"
  @rpl_welcome "001"
  @rpl_yourhost "002"
  @rpl_created "003"
  @rpl_myinfo "004"
  @err_nicknameinuse "433"

  def new(client, msg_id, nick, data) do
    {client, ":#{client.server.host} #{msg_id} #{nick} #{data}"}
  end

  def welcome(client, %{nick: nick} = user) do
    [
      new(client, @rpl_welcome, nick, ":Welcome to #{client.server.host}"),
      new(client, @rpl_yourhost, nick, ":Your host is exirc running version #{@version}"),
      new(client, @rpl_created, nick, ":This server was created 2016-09-03"),
      new(client, @rpl_myinfo, nick, "exirc #{@version} oiv r\"")
    ]
  end

  def nick_in_use(client, user) do
    new(client, @err_nicknameinuse, user.nick, "#{user.nick} :Nickname is already in use.")
  end
end