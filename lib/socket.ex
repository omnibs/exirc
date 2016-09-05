defmodule Socket do
	require Logger

	@version "16.09.03"
	@rpl_welcome "001"
	@rpl_yourhost "002"
	@rpl_created "003"
	@rpl_myinfo "004"

	def open(port) do
		{:ok, socket} = :gen_tcp.listen(port,
			[:binary, packet: :line, active: false, reuseaddr: true])
		Logger.info "Accepting connections on port #{port}"
		accept_connections(socket)
	end

	defp accept_connections(socket) do
		{:ok, client} = :gen_tcp.accept(socket)
		bootstrap(client)
		accept_connections(socket)
	end

	defp bootstrap(client) when is_port(client) do
		:gen_tcp.send(client, "\r\n") |> IO.inspect

		starting_state = %{
			client: client, 
			is_welcome: false,
			out_buffer: [],
			server: %{
				host: "127.0.0.1" #todo: make this configurable
			}
		}

		serve_client(starting_state)
	end

	defp serve_client(%{client: client} = state) when is_port(client) do
		case :gen_tcp.recv(client, 0) do
			{:ok, data} ->
				data = String.trim_trailing(data, "\r\n")
				IO.puts("#{inspect(client)} - #{inspect(data)}")
				process(data, state)
				|> dispatch()
				|> serve_client()
			{:error, :closed} ->
				IO.puts("#{inspect(client)} - closed connection")
			{:error, other} ->
				IO.puts("#{inspect(client)} - ERROR: #{inspect(other)}")
		end
	end

	defp process("NICK " <> nick, state) do
		IO.puts("User #{nick} has joined")
		Map.put(state, :nick, nick)
		|> send_welcome()
	end

	defp process("USER " <> userdata, state) do
		IO.puts("Userdata: #{userdata}")
		Map.put(state, :userdata, userdata)
		|> send_welcome()
	end

	defp process(unknown_msg, state) do
		IO.puts("unknown_msg: #{inspect(unknown_msg)}")
		state
	end

	defp send_welcome(%{is_welcome: false} = state) do
		state
		|> add_message(@rpl_welcome, ":Welcome to #{state.server.host}")
		|> add_message(@rpl_yourhost, ":Your host is exirc running version #{@version}")
		|> add_message(@rpl_created, ":This server was created 2016-09-03")
		|> add_message(@rpl_myinfo, "exirc #{@version} oiv r\"")
	end
	defp send_welcome(%{is_welcome: true}) do end

	defp add_message(state, msg_id, data) do
		msg = ":#{state.server.host} #{msg_id} #{state.nick} #{data}"
		{_, state} = Map.get_and_update(state, :out_buffer, fn (list) -> {list, [msg | list]} end)
		state
	end

	defp dispatch(%{out_buffer: []} = state) do
		state
	end
	defp dispatch(%{out_buffer: buffer, client: client} = state) do
		Enum.reduce(buffer, nil, fn (msg, _acc) -> 
			IO.puts("Sent:\n#{msg}")
			:gen_tcp.send(client, msg)
		end)
		Map.put(state, :out_buffer, [])
	end
end

Socket.open(6667)