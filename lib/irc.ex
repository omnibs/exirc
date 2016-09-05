defmodule IRC do
	require Logger

	@version "16.09.03"
	@rpl_welcome "001"
	@rpl_yourhost "002"
	@rpl_created "003"
	@rpl_myinfo "004"

	def process("NICK " <> nick, state) do
		Logger.info "User #{nick} has joined"
		Map.put(state, :nick, nick)
		|> send_welcome()
	end

	def process("USER " <> userdata, state) do
		Logger.info "#{state.nick} is #{userdata}"
		Map.put(state, :userdata, userdata)
		|> send_welcome()
	end

	def process(unknown_msg, state) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
		state
	end

	def send_welcome(%{is_welcome: false} = state) do
		state
		|> add_message(@rpl_welcome, ":Welcome to #{state.server.host}")
		|> add_message(@rpl_yourhost, ":Your host is exirc running version #{@version}")
		|> add_message(@rpl_created, ":This server was created 2016-09-03")
		|> add_message(@rpl_myinfo, "exirc #{@version} oiv r\"") #todo: actually have modes

		%{state | is_welcome: true}
	end
	def send_welcome(%{is_welcome: true} = state) do
		state
	end

	def add_message(state, msg_id, data) do
		msg = ":#{state.server.host} #{msg_id} #{state.nick} #{data}"
		{_, state} = Map.get_and_update(state, :out_buffer, fn (list) -> {list, [msg | list]} end)
		state
	end
end