defmodule UserRegistry do
  defstruct nick_map: %{}, port_map: %{}

  def start_link do
    Agent.start_link(fn -> %UserRegistry{} end, name: __MODULE__)
  end

  def new(port) do
    Agent.update(__MODULE__, fn registry -> 
      pid = User.new(%{port: port})
      %{registry | port_map: Map.put(registry.port_map, port, pid)}
    end)
  end

  def pid_from_nick(nick) do
    Agent.get(__MODULE__, fn registry -> registry.nick_map[nick] end)
  end

  def pid_from_port(port) do
    Agent.get(__MODULE__, fn registry -> registry.port_map[port] end)
  end

  def destroy do
    Agent.stop(__MODULE__)
  end

end