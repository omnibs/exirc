defmodule NickChangeProcessor do

  def change_nick(old_nick, new_nick) do
    Agent.get_and_update(NickRegistry, fn registry ->
      if Map.has_key?(registry.nick_map, old_nick) do
        %{^old_nick => pid} = registry.nick_map


        {:ok, %{ registry | nick_map: Map.put(registry.nick_map, new_nick, pid) } }
      else
        {:error, registry}
      end
    end)
  end

  def set_nick(nick, pid, port) do
    Agent.get_and_update(NickRegistry, fn registry ->
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

end