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


  def change_nick(old_nick, new_nick) do
    Agent.get_and_update(__MODULE__, fn registry ->
      if Map.has_key?(registry.nick_map, old_nick) do
        %{^old_nick => pid} = registry.nick_map
        {:ok, %{ registry | nick_map: %{registry.nick_map | new_nick => pid } } }
      else
        {:error, registry}
      end
    end)
  end

  def set_nick(nick, pid, port) do
    Agent.get_and_update(__MODULE__, fn registry ->
      if Map.has_key?(registry.nick_map, nick) do
        {:error, registry}
      else
        {:ok, %NickRegistry{ nick_map: Map.put(registry.nick_map, nick, pid),
                             port_map: Map.put(registry.port_map, pid, port)
                           }
        }
      end
    end)
  end

  def destroy do
    Agent.stop(__MODULE__)
  end

end