defmodule App do
  use Application
  use Supervisor
    #import Supervisor.Spec, warn: false


  def start(_type, _args) do
    children = [
      supervisor(SocketSupervisor, []),
      supervisor(RepositorySupervisor, []),
      ]
    opts = [strategy: :one_for_all]
    Supervisor.start_link(children, opts)
  # Socket.open(6667)
  end
end
