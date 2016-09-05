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
				host: "127.0.0.1" #todo: make this configurable
			}
		}

		# idk but apparently I have to send something before client sends me shit
		:gen_tcp.send(client, "\r\n")

		serve_client(starting_state)
	end

	defp serve_client(%{client: client} = state) when is_port(client) do
		case :gen_tcp.recv(client, 0) do
			{:ok, data} ->
				data = String.trim_trailing(data, "\r\n")
				
				Logger.info "<- #{inspect(client)} - #{inspect(data)}"
				
				IRC.process(data, state)
				|> dispatch()
				|> serve_client()
			{:error, :closed} ->
				Logger.info "#{inspect(client)} - closed connection"
			{:error, other} ->
				Logger.info "#{inspect(client)} - ERROR: #{inspect(other)}"
		end
	end

	defp dispatch(%{out_buffer: []} = state) do
		state
	end
	defp dispatch(%{out_buffer: buffer, client: client} = state) do
		Enum.reduce(buffer, nil, fn (msg, _acc) -> 
			Logger.info "-> #{msg}"
			:gen_tcp.send(client, msg)
		end)
		Map.put(state, :out_buffer, [])
	end
end