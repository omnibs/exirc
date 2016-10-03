defmodule NickChangeProcessor do
  def change_nick(pid, new_nick) do
    Agent.get_and_update(NickRegistry, fn registry ->
      user = User.user(pid)
      
      case Map.get(registry.nick_map, new_nick) do
        nil ->
          registry = pop_in(registry, [:nick_map, user.nick])
          registry = put_in(registry, [:nick_map, new_nick], new_nick)

          User.set_nick(pid, new_nick)

          {:ok, registry}
        %{pid: ^pid} -> 
          {:noop, registry}
        _ -> 
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