defmodule App do
    use Application
    use Supervisor
    #import Supervisor.Spec, warn: false


    def start(_type, _args) do
        children = [
            supervisor(SocketSupervisor, []), 
            # worker(Users, [[], [name: Users]]), 
            # worker(Channels, [[], [name: Channels]]), 
            # worker(ChannelUsers, [[], [name: ChannelUsers]])
        ]
        opts = [strategy: :rest_for_one]
        Supervisor.start_link(children, opts)
        # Socket.open(6667)
    end
end

defmodule SocketSupervisor do
    use Supervisor

    def start_link do
        children = Enum.map(ports(), fn (x) -> 
            worker(Socket, [x], id: String.to_atom("Socket#{x}"))
        end)
        Supervisor.start_link(children, [strategy: :one_for_one])
    end

    def ports do
        [6667, 6668, 6669]
    end
end