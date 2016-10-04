defmodule SocketReadClient do
  require Logger
  use GenServer

  def start(port, write_process) do
    GenServer.start(__MODULE__, {port, write_process}, [name: String.to_atom("ReadClient#{inspect(port)}")])
  end

  def init({port, write_process}) do
    Logger.info "bootstrapping"
    GenServer.cast(self, :bootstrap)
    {:ok, %{port: port, write_process: write_process}}
  end

  def handle_cast(:bootstrap, %{port: port, write_process: write_process}) do
    starting_client = %{
      client: port,
      out_buffer: [],
      server: %{
        host: "localhost" #todo: make this configurable
      }
    }

    pid = IRC.new_user(port, write_process)
    send(write_process, {:agent, pid})

    receive_loop(starting_client)
  end

  defp receive_loop(%{client: port} = client) when is_port(port) do
    case :gen_tcp.recv(port, 0) do
      {:ok, data} ->
        data = String.trim_trailing(data, "\r\n")

        Logger.info "<- #{inspect(port)} - #{inspect(data)}"

        if IRC.allowed?(data, client) do
          data
          |> CommandDelegator.process(client)

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
end