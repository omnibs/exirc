defmodule IRC do
	require Logger

	@version "16.09.03"
	@rpl_welcome "001"
	@rpl_yourhost "002"
	@rpl_created "003"
	@rpl_myinfo "004"
	@err_nicknameinuse "433"

	def new_user(client) when is_port(client) do
		Users.register(client)
	end

	def process("NICK " <> nick, client) do
		Logger.info "User #{nick} has joined"
		
		# not sure if I should keep this pure...
		# just sure as hell it shouldn't go into socketclient
		case Users.change_nick(client.client, nick) do
			{:ok, user} -> client
			{:error, user} ->
				add_message(client, @err_nicknameinuse, user.nick, "#{nick} :Nickname is already in use.")
		end
	end

	def process("USER " <> userdata, client) do
		user = Users.update_info(client.client, userdata)
		send_welcome(client, user)
	end

	def process("PRIVMSG " <> data, client) do
		[nick, msg] = String.split(data, " ", parts: 2)
		":" <> msg = msg
		[from, to] = Users.resolve_users([client.client, nick])
		SocketClient.send_msg(to.client, ":#{from.nick} PRIVMSG #{to.nick} :#{msg}")
		client
	end

	def process(unknown_msg, client) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
		client
	end

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
		IO.inspect(_user)
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