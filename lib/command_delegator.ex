defmodule CommandDelegator do
	require Logger

	def new_user(port) do
		UserRegistry.register(port)
	end


	def process("NICK " <> nick, port) do
		pid = get_pid(port)
		_status = NickChangeProcessor.change_nick(pid, nick)
	end

	def process("USER " <> _userdata, _port) do

	end

	def process("PRIVMSG " <> _data, _port) do

	end

	def process(unknown_msg, _port) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
	end

	defp get_pid(port), do: UserRegistry.pid_from_port(port)
end
