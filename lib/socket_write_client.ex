defmodule SocketWriteClient do
  require Logger
  use GenServer

  def start(port) do
    GenServer.start(__MODULE__, port, [name: String.to_atom("WriteClient#{inspect(port)}")])
  end

  def init(port) do
    Logger.info "bootstrapping"
    GenServer.cast(self, :bootstrap)
    {:ok, %{port: port}}
  end

  def handle_cast(:bootstrap, %{port: port}) do
    :gen_tcp.send(port, "\r\n")
    pid = receive do
      {:agent, agent_pid} -> agent_pid
    end
    write_loop(port, pid)
  end

  defp write_loop(port, pid) when is_port(port) and is_pid(pid) do
    receive do
      {:message, message} ->
        send_msg(port, message)
    end
    write_loop(port, pid)
  end

  defp send_msg(port, msg) when is_port(port) do
    Logger.info "-> #{msg}"
    :gen_tcp.send(port, msg <> "\r\n")
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