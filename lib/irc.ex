defmodule IRC do
	require Logger

	def new_user(client) when is_port(client) do
		Users.register(client)
	end


	def process("NICK " <> nick, client) do
		Logger.info "User #{nick} has joined"

		result = Users.change_nick(client.client, nick)
		{_ok, user, _old_nick, msgs} = result
		channel_mates = Channel.get_channel_mates(user)
		msgs = msgs ++ NickChangeResultProcessor.process(result, client, channel_mates)
		SocketOutput.send(msgs)
		client
	end

	def process("USER " <> userdata, client) do
		{user, msgs} = Users.update_info(client.client, userdata)
		#send_welcome(client, user)
		SocketOutput.send(msgs)
	end

	def process("PRIVMSG " <> data, client) do
		[nick, msg] = String.split(data, " ", parts: 2)
		":" <> msg = msg

		[from, to] = Users.resolve_users([client.client, nick])
		# TODO: send `recipient_nick :No such nick/channel`
		# TODO: use socketoutput
		SocketClient.send_msg(to.client, ":#{from.nick} PRIVMSG #{to.nick} :#{msg}")
		client
	end

	def process(unknown_msg, client) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
		client
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