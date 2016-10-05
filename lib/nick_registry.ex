defmodule NickRegistry do
  defstruct nick_map: %{}, port_map: %{}

  def start_link do
    Agent.start_link(fn -> %NickRegistry{} end, name: __MODULE__)
  end

  def pid(nick) do
    Agent.get(__MODULE__, fn registry -> registry.nick_map[nick] end)
  end

  def port(nick) do
    Agent.get(__MODULE__, fn registry -> registry.port_map[registry.nick_map[nick]] end)
  end

  def destroy do
    Agent.stop(__MODULE__)
  end

end