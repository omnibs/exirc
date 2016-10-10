defmodule RoomProcessor do
  def join(room_or_rooms, user_pid) do
    each_room(room_or_rooms, fn room ->
      RoomRegistry.pid_from_channel(room)
      |> Room.add_user(user_pid)
    end)
    # TODO send to user who joined
    # JOIN reply:
    # :jasnira!~Juliano@207.251.103.46 JOIN #channel * :realname

    # RPL_NAMREPLY:
    # :serverhost 353 jasnira @ #channel :@jasnira

    # RPL_ENDOFNAMES:
    # :serverhost 366 jasnira #channel :End of /NAMES list.

    # TODO send to other users:
    # idk we gotta tcpdump/wireshark and see
  end

  def part(room_or_rooms, user_pid) do
    each_room(room_or_rooms, fn room ->
      RoomRegistry.pid_from_channel(room)
      |> Room.remove_user(user_pid)
    end)
    # TODO send reply to user
    # TODO notify people on the channel
  end

  defp each_room(rooms, room_function) do
    String.split(rooms, ",")
    |> Enum.each(room_function)
  end
end
