defmodule UserRegistry do
  defstruct nick_map: %{}, port_map: %{}

  def start_link do
    Agent.start_link(fn -> %UserRegistry{} end, name: __MODULE__)
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