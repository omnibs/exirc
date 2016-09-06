defmodule IRC do
	require Logger

	@version "16.09.03"
	@rpl_welcome "001"
	@rpl_yourhost "002"
	@rpl_created "003"
	@rpl_myinfo "004"
	@err_nicknameinuse "433"

	def process("NICK " <> nick, state) do
		Logger.info "User #{nick} has joined"
		
		# not sure if I should keep this pure...
		# just sure as hell it shouldn't go into socketclient
		case Users.new_user(nick, state.client) do
			:ok ->
				Map.put(state, :nick, nick)
				|> send_welcome()
			:error ->
				add_message(
					state, 
					":#{state.server.host} #{@err_nicknameinuse} * #{nick} :Nickname is already in use."
				)
		end
	end

	def process("USER " <> userdata, state) do
		Map.put(state, :userdata, userdata)
		|> send_welcome()
	end

	def process("PRIVMSG " <> data, state) do
		[nick, msg] = String.split(data, " ", parts: 2)
		":" <> msg = msg
		Users.private_message(state.nick, nick, msg)
		state
	end

	def process(unknown_msg, state) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
		state
	end

	def send_welcome(%{is_welcome: false, nick: _nick, userdata: _userdata} = state) do
		Logger.info "Sending full welcome"
		state = state
		|> add_message(@rpl_welcome, ":Welcome to #{state.server.host}")
		|> add_message(@rpl_yourhost, ":Your host is exirc running version #{@version}")
		|> add_message(@rpl_created, ":This server was created 2016-09-03")
		|> add_message(@rpl_myinfo, "exirc #{@version} oiv r\"") #todo: actually have modes

		%{state | is_welcome: true}
	end

	def send_welcome(state) do
		Logger.info "Not logged in yet"
		state
 	end

	def add_message(state, msg_id, data) do
		msg = ":#{state.server.host} #{msg_id} #{state.nick} #{data}"
		{_, state} = Map.get_and_update(state, :out_buffer, fn (list) -> {list, [msg | list]} end)
		state
	end

	def add_message(state, msg) do
		{_, state} = Map.get_and_update(state, :out_buffer, fn (list) -> {list, [msg | list]} end)
		state
	end
end