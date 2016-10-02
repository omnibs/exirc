defmodule SocketClient do
	require Logger
	use GenServer

	def start(port) do
		GenServer.start(__MODULE__, port, [name: String.to_atom("Client#{inspect(port)}")])
	end

	def init(port) do
		Logger.info "bootstrapping"
		GenServer.cast(self, :bootstrap)
		{:ok, %{port: port}}
	end

	def send_msg(port, msg) when is_port(port) do
		Logger.info "-> #{msg}"
		:gen_tcp.send(port, msg <> "\r\n")
	end

	def handle_cast(:bootstrap, %{port: port}) do
		starting_client = %{
			client: port,
			out_buffer: [],
			server: %{
				host: "localhost" #todo: make this configurable
			}
		}

		# idk but apparently I have to send something before port sends me shit
		:gen_tcp.send(port, "\r\n")
		IRC.new_user(port)

		receive_loop(starting_client)
	end

	defp receive_loop(%{client: port} = client) when is_port(port) do
		case :gen_tcp.recv(port, 0) do
			{:ok, data} ->
				data = String.trim_trailing(data, "\r\n")

				Logger.info "<- #{inspect(port)} - #{inspect(data)}"

				if IRC.allowed?(data, client) do
					data
					|> IRC.process(client)
					|> dispatch
					|> receive_loop()
				else
					receive_loop(client)
				end
			{:error, :closed} ->
				Logger.info "#{inspect(port)} - closed connection"
				GenServer.stop(self)
			{:error, other} ->
				Logger.info "#{inspect(port)} - ERROR: #{inspect(other)}"
				GenServer.stop(self, {:shutdown, other})
		end
	end

	defp dispatch(%{out_buffer: []} = client) do
		Logger.info "Nothing to send out"
		client
	end
	defp dispatch(%{out_buffer: buffer, client: port} = client) do
		Logger.info "Dispatching..."
		Enum.each(buffer, fn (msg) ->
			send_msg(port, msg)
		end)
		Map.put(client, :out_buffer, [])
	end
end