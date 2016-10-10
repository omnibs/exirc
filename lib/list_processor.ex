defmodule ListProcessor do
  def list(user_pid) do
    user_data = User.data(user_pid)
    output = user_data.output
    nick = user_data.nick
    SocketWriteClient.message(output, Msgformat.start_list(nick))
    Enum.each(RoomRegistry.rooms, fn room_pid ->
      SocketWriteClient.message(output, Msgformat.list_room(nick, Room.data(room_pid)))
    end)
    SocketWriteClient.message(output, Msgformat.end_list(nick))
  end

end
