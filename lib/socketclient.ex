defmodule SocketClient do
	require Logger
	use GenServer

	def start(client) do
		GenServer.start(__MODULE__, client, [name: String.to_atom("Client#{inspect(client)}")])
	end

	def init(client) do
		Logger.info "bootstrapping"
		GenServer.cast(self, :bootstrap)
		{:ok, %{client: client}}
	end

	def handle_cast(:bootstrap, %{client: client}) do
		starting_state = %{
			client: client, 
			is_welcome: false,
			out_buffer: [],
			server: %{
				host: "localhost" #todo: make this configurable
			}
		}

		# idk but apparently I have to send something before client sends me shit
		:gen_tcp.send(client, "\r\n")

		receive_loop(starting_state)
	end

	defp receive_loop(%{client: client} = state) when is_port(client) do
		case :gen_tcp.recv(client, 0) do
			{:ok, data} ->
				data = String.trim_trailing(data, "\r\n")
				
				Logger.info "<- #{inspect(client)} - #{inspect(data)}"

				IRC.process(data, state)
				|> dispatch()
				|> receive_loop()
			{:error, :closed} ->
				Logger.info "#{inspect(client)} - closed connection"
				GenServer.stop(self)
			{:error, other} ->
				Logger.info "#{inspect(client)} - ERROR: #{inspect(other)}"
				GenServer.stop(self, {:shutdown, other})
		end
	end

	defp dispatch(%{out_buffer: []} = state) do
		Logger.info "Nothing to send out"
		state
	end
	defp dispatch(%{out_buffer: buffer, client: client} = state) do
		Logger.info "Dispatching..."
		Enum.reduce(buffer, nil, fn (msg, _acc) -> 
			Logger.info "-> #{msg}"
			:gen_tcp.send(client, msg <> "\r\n")
		end)
		Map.put(state, :out_buffer, [])
	end
end