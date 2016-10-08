defmodule UserRegistry do
  defstruct nick_map: %{}, port_map: %{}
  @type t :: %__MODULE__{nick_map: %{}, port_map: %{}}

  def start_link do
    Agent.start_link(fn -> %UserRegistry{} end, name: __MODULE__)
  end

  def register(port, writer) do
    Agent.get_and_update(__MODULE__, fn registry ->
      pid = User.new(%{port: port, output: writer})
      {pid, %{registry | port_map: Map.put(registry.port_map, port, pid)}}
    end)
  end

  def unregister(pid) do
    Agent.update(__MODULE__, fn registry -> 
      data = User.data(pid)
      %UserRegistry{
        port_map: Map.pop(registry.port_map, data.port),
        nick_map: Map.pop(registry.nick_map, data.nick)
      }
    end)
  end

  def pid_from_nick(nick) do
    Agent.get(__MODULE__, fn registry -> registry.nick_map[nick] end)
  end

  def pid_from_port(port) do
    Agent.get(__MODULE__, fn registry -> registry.port_map[port] end)
  end

  def destroy do
    # Agent.stop(__MODULE__)
    Agent.update(__MODULE__, fn _ -> %UserRegistry{} end)
  end

end
