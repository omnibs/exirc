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
    pid = UserRegistry.register(port, write_process)

    connection_info = %{
      port: port,
      output: write_process,
      agent: pid,
      server: %{
        host: "localhost" #todo: make this configurable
      }
    }

    receive_loop(connection_info)
  end

  defp receive_loop(%{port: port} = connection_info) when is_port(port) do
    case :gen_tcp.recv(port, 0) do
      {:ok, data} ->
        data = String.trim_trailing(data, "\r\n")

        Logger.info "<- #{inspect(port)} - #{inspect(data)}"

        CommandDelegator.process(data, connection_info.agent)

        receive_loop(connection_info)
      {:error, :closed} ->
        Logger.info "#{inspect(port)} - closed connection"
        GenServer.stop(self)
        cleanup(connection_info, :normal)
      {:error, other} ->
        Logger.info "#{inspect(port)} - ERROR: #{inspect(other)}"
        GenServer.stop(self, {:shutdown, other})
        cleanup(connection_info, {:shutdown, other})
    end
  end

  defp cleanup(connection_info, state) do  
    # TODO: remove from channels


    # remove it from the UserRegistry
    UserRegistry.unregister(connection_info.agent)

    # kill the user 
    User.destroy(connection_info.agent)
    
    # kill the writer 
    GenServer.stop(connection_info.output, state)
  end
end

