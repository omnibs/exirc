defmodule NickRegistry do
  defstruct nick_map: %{}, port_map: %{}

  def start_link do
    Agent.start_link(fn -> %NickRegistry{} end, name: __MODULE__)
  end

  def nick(nick) do
    Agent.get(__MODULE__, fn registry -> registry.nick_map[nick] end)
  end

  def change_nick(old_nick, new_nick) do
    Agent.get_and_update(__MODULE__, fn
      registry = %NickRegistry{nick_map: %{^old_nick => pid} } ->
        {:ok, %{ registry | nick_map: %{registry.nick_map | new_nick => pid } } }
      registry ->
        {:error, registry}
    end)
  end

  def set_nick(nick, pid, port) do
    Agent.get_and_update(__MODULE__, fn
      registry = %NickRegistry{nick_map: %{^nick => pid} } ->
        {:error, registry}
      registry ->
        {:ok, %NickRegistry{ nick_map: %{registry.nick_map | nick => pid }, port_map: %{registry.port_map | port => pid } } }
    end)
  end

  def destroy do
    Agent.stop(__MODULE__)
  end

end