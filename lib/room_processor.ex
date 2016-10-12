defmodule RoomProcessor do
  def join(room_or_rooms, user_pid) do
    each_room(room_or_rooms, fn room ->
      RoomRegistry.pid_from_channel(room)
      |> Room.add_user(user_pid)

      # TODO send to user who joined
      # JOIN reply:
      # :jasnira!~Juliano@207.251.103.46 JOIN #channel * :realname
      notify_joiner(user_pid, room)

      # RPL_NAMREPLY:
      # :serverhost 353 jasnira @ #channel :@jasnira

      # RPL_ENDOFNAMES:
      # :serverhost 366 jasnira #channel :End of /NAMES list.

      # other example where user is not OP and there are other users in the channel:
      # :asimov.freenode.net 353 joining_user_nickname = #somechan :joining_user_nickname @ChanServ omnibs
      # :asimov.freenode.net 366 joining_user_nickname #somechan :End of /NAMES list.
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

  defp notify_joiner(user_pid, room) do
    out_pid = User.output(user_pid)
    mask = User.mask(user_pid)
    name = User.name(user_pid)
    msg = Msgformat.join_reply(mask, room, name)
    SocketWriteClient.message(out_pid, msg)
  end
end
