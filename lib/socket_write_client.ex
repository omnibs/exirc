defmodule SocketWriteClient do
  require Logger
  use GenServer

  def start(port) do
    GenServer.start(__MODULE__, port)
  end

  def message(pid, msg) do
    GenServer.cast(pid, {:message, msg})
  end

  def init(port) do
    Logger.info "bootstrapping"
    GenServer.cast(self, :bootstrap)
    {:ok, port}
  end

  def handle_cast(:bootstrap, port) do
    :gen_tcp.send(port, "\r\n")
    {:noreply, port}
  end

  def handle_cast({:message, msg}, port) do
    send_msg(port, msg)
    {:noreply, port}
  end

  defp send_msg(port, msg) when is_port(port) do
    Logger.info "-> #{msg}"
    :gen_tcp.send(port, msg <> "\r\n")
  end
end

