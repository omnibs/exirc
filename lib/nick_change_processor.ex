defmodule NickChangeProcessor do
  def change_nick(pid, new_nick) do
    Agent.get_and_update(UserRegistry, fn registry ->
      user = User.data(pid)
      case Map.get(registry.nick_map, new_nick) do
        ^pid  ->
          {:noop, registry}
        nil ->
          {_old_name_if_present, nick_map} = Map.pop(registry.nick_map, user.nick)
          registry = %{registry| nick_map: nick_map}
          registry = %{registry| nick_map: Map.put(registry.nick_map, new_nick, pid)}

          User.set_nick(pid, new_nick)

          {:ok, registry}
        _ ->
          {:error, registry}
      end
    end)
  end

end