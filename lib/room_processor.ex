defmodule RoomProcessor do
  def join(room_or_rooms, user_pid) do
    each_room(room_or_rooms, fn room ->
      room_pid = RoomRegistry.pid_from_channel(room)

      users_pids = Room.users(room_pid)
      users_data = Enum.map(users_pids, fn user -> User.data(user) end)
      my_data = User.data(user_pid)
      
      Room.add_user(room_pid, user_pid)

      # JOIN reply:
      # :jasnira!~Juliano@207.251.103.46 JOIN #channel * :realname
      [my_data | users_data]
      |> Enum.each(fn user_data -> notify_user(user_data.output, my_data, room) end)

      send_names(my_data, users_data, room)
    end)
  end

  def part(room_or_rooms, user_pid) do
    each_room(room_or_rooms, fn room ->
      RoomRegistry.pid_from_channel(room)
      |> Room.remove_user(user_pid)
    end)
    # TODO send reply to user
    # TODO notify people on the channel
    # :jasnira!~Juliano@207.251.103.46 PART #somechan
  end

  defp each_room(rooms_string, room_function) do
    String.split(rooms_string, ",")
    |> Enum.each(room_function)
  end

  defp notify_user(out_pid, %{name: name, mask: mask}, room) do
    msg = Msgformat.join_reply(mask, room, name)
    SocketWriteClient.message(out_pid, msg)
  end

  defp send_names(me, others, room) do
    Msgformat.names([me | others], me.nick, room)
    |> Enum.each(fn msg ->
      SocketWriteClient.message(me.output, msg)
    end)
    
    endofnames = Msgformat.end_names(me.nick, room)
    SocketWriteClient.message(me.output, endofnames)
  end
end
