defmodule SocketSupervisor do
  use Supervisor

  def start_link do
    children = Enum.map(ports, fn (x) ->
            # TODO: either kill to_atom here or at socket.ex
            worker(Socket, [x], id: String.to_atom("Socket#{x}"))
          end)
    Supervisor.start_link(children, [strategy: :one_for_one])
  end

  def ports do
    [6667, 6668, 6669]
  end
end
