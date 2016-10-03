defmodule CommandDelegator do
	require Logger

	def new_user(port) do
		
	end


	def process("NICK " <> nick, port) do
		pid = get_pid(port)
		NickChangeProcessor.change_nick(pid, nick)
	end

	def process("USER " <> userdata, port) do

	end

	def process("PRIVMSG " <> data, port) do

	end

	def process(unknown_msg, port) do
		Logger.info "unknown_msg: #{inspect(unknown_msg)}"
	end

	defp get_pid(port) do
		nil # TODO: Use new UserRegistry
	end
end
