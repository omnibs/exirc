defmodule Socket do
	require Logger
	use GenServer

	def start_link(port) do
		GenServer.start_link(__MODULE__, port, [name: String.to_atom("Socket#{port}")])
	end

	def init(port) do
		response = {:ok, socket} = :gen_tcp.listen(port,
		 	[:binary, packet: :line, active: false, reuseaddr: true])
		Logger.info "Accepting connections on port #{port}"
		
		GenServer.cast(self, :accept)
		response
	end

	def handle_cast(:accept, socket) do
		{:ok, client} = :gen_tcp.accept(socket)
		Logger.info ">>New client<<"
		
		SocketClient.start(client)

		handle_cast(:accept, socket)
	end
end
