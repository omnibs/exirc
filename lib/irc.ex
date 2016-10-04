defmodule IRC do
  require Logger

  def new_user(port, writer) when is_port(port) and is_pid(writer) do
    UserRegistry.register(port, writer)
  end

  def allowed?("NICK" <> _, %{booting: true}), do: true
  def allowed?("USER" <> _, %{booting: true}), do: true
  def allowed?(_, %{booting: true}), do: false
  def allowed?(_, __), do: true

  def send_welcome(client, %{is_welcome: false, nick: nick, info: _info} = user) do
    Logger.info "Sending full welcome"
    Users.mark_welcomed(nick)

    client
    |> add_message(@rpl_welcome, nick, ":Welcome to #{client.server.host}")
    |> add_message(@rpl_yourhost, nick, ":Your host is exirc running version #{@version}")
    |> add_message(@rpl_created, nick, ":This server was created 2016-09-03")
    |> add_message(@rpl_myinfo, nick, "exirc #{@version} oiv r\"") #todo: actually have modes
  end

  def send_welcome(client, _user) do
    Logger.info "Not logged in yet"
    client
  end

  def add_message(client, msg_id, nick, data) do
    msg = ":#{client.server.host} #{msg_id} #{nick} #{data}"
    {_, client} = Map.get_and_update(client, :out_buffer, fn (list) -> {list, [msg | list]} end)
    client
  end

  def add_message(client, msg) do
    {_, client} = Map.get_and_update(client, :out_buffer, fn (list) -> {list, [msg | list]} end)
    client
  end


end

# :oldnick!~realname@some.masked.host NICK :new_nickname