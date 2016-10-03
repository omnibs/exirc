defmodule SocketOutput do
  require Logger

  def send(msgs) do
    Enum.each msgs, fn {port, msg} ->
      Logger.info "-> #{inspect(port)} #{msg}"
      :gen_tcp.send(port, msg)
    end
  end
  def send(nil) do
    Logger.info "weird, trying to send empty"
  end
end