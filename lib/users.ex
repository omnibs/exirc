defmodule Users do
	use GenServer

	def start_link do
		GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
	end

	def init(state) do
		{:ok, state}
	end

	def new_user(nick, client) when is_port(client) do
		GenServer.call(__MODULE__, {:new_user, nick, client})
	end

	def handle_call({:new_user, nick, client}, _from, state) do
		case Map.has_key?(state, nick) do
			false -> 
				state = Map.put(state, nick, client)
				{:reply, :ok, state}
			true -> 
				{:reply, :error, state}
		end
	end
end