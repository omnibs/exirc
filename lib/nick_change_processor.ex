defmodule NickChangeProcessor do
  @spec change_nick(pid(), String.t) :: atom()
  def change_nick(pid, new_nick) do
    Agent.get_and_update(UserRegistry, fn registry ->
      do_change_nick(pid, new_nick, registry)
    end)
    |> notify_people(pid, new_nick)
  end

  @spec do_change_nick(pid(), String.t, UserRegistry.t) :: {{atom(), User.t}, UserRegistry.t}
  defp do_change_nick(pid, new_nick, registry) do
    user = User.data(pid)
    case Map.get(registry.nick_map, new_nick) do
      ^pid  ->
        {{:noop, user}, registry}
      nil ->
        {_old_name_if_present, nick_map} = Map.pop(registry.nick_map, user.nick)
        registry = %{registry| nick_map: nick_map}
        registry = %{registry| nick_map: Map.put(registry.nick_map, new_nick, pid)}

        User.set_nick(pid, new_nick)

        {{:ok, user}, registry}
      _ ->
        {{:error, user}, registry}
    end
  end

  @spec notify_people({:noop | :error | :ok, User.t}, pid(), String.t) :: atom()
  defp notify_people({:noop, _user}, _user_pid, _new_nick) do
    :noop
  end
  defp notify_people({:error, user}, user_pid, new_nick) do
    msg = Msgformat.nick_in_use(user.nick, new_nick)
    out_pid = User.output(user_pid)
    SocketWriteClient.message(out_pid, msg)
    :error
  end
  defp notify_people({:ok, user}, user_pid, new_nick) do
    # manual is_welcome? check, user_pid already reflects nick change
    cond do 
      user.name && user.nick ->
        out_pid = User.output(user_pid)
        msg = Msgformat.nick_changed(user.mask, new_nick)
        SocketWriteClient.message(out_pid, msg)
        # TODO: write same message to all room mates
      user.name ->
        out_pid = User.output(user_pid)
        Msgformat.welcome(new_nick)
        |> Enum.each(fn msg ->
          SocketWriteClient.message(out_pid, msg)
        end)
      true -> nil # no msg from nick change during login
    end
    :ok
  end
end
