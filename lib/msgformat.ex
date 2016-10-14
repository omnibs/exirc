defmodule Msgformat do
  @create_date Application.get_env(:exircd, :create_date) || "2016-10-07"
  @version "16.10.07"
  @rpl_welcome "001"
  @rpl_yourhost "002"
  @rpl_created "003"
  @rpl_myinfo "004"
  @rpl_liststart "321"
  @rpl_list "322"
  @rpl_listend "323"
  @rpl_namreply "353"
  @rpl_endofnames "366"
  @err_nicknameinuse "433"
  @server_host Application.get_env(:exircd, :server_host) || "localhost"
  def new(msg_id, nick, data) do
    "#{prefix} #{msg_id} #{nick || "*"} #{data}"
  end

  def welcome(nil) do
    raise WAT
  end

  def welcome(nick) do
    [
      new(@rpl_welcome, nick, ":Welcome to #{host}"),
      new(@rpl_yourhost, nick, ":Your host is exirc running version #{@version}"),
      new(@rpl_created, nick, ":This server was created #{@create_date}"),
      new(@rpl_myinfo, nick, "exircd #{@version} oiv r\"")
    ]
  end

  def nick_in_use(old_nick, new_nick) do
    new(@err_nicknameinuse, old_nick, "#{new_nick} :Nickname is already in use.")
  end

  def nick_changed(mask, new_nick) do
    "#{prefix} #{mask} NICK :#{new_nick}"
  end

  def start_list(nick) do
    "#{prefix} #{@rpl_liststart} #{nick} Channel :Users  Name"
  end

  def list_room(nick, room_data) do
    "#{prefix} #{@rpl_list} #{nick} #{room_data.channel} #{length(room_data.users)} :#{room_data.topic}"
  end

  def end_list(nick) do
    "#{prefix} #{@rpl_listend} #{nick} :End of /LIST"
  end

  def join_reply(mask, room, user_name) do
    ":#{mask} JOIN #{room} * :#{user_name}"
  end

  # :asimov.freenode.net 353 joining_user_nickname = #somechan :joining_user_nickname @ChanServ omnibs
  def names([%User{} | t] = users, nick, room) do
    users
    |> Enum.map(& &1.nick)
    |> names(nick, room)
  end
  def names(users, nick, room) do
    users
    |> name_chunks()
    |> Enum.map(fn chunk ->
      "#{prefix} #{@rpl_namreply} #{nick} = #{room} :#{chunk}"
    end)
  end

  defp name_chunks(users) do
    {result, acc, _} =
    Enum.reduce(users, {[], "", 0}, fn x, {result, acc, len} ->
      x_len = String.length(x)
      new_len = x_len + len + 1 # +1 accounts for space
      cond do
         new_len < 460 ->
          {result, x <> " " <> acc, new_len}
         true ->
          {[String.trim_trailing(acc) | result], x, x_len}
      end
    end)
    [String.trim_trailing(acc) | result]
  end

  def end_names(nick, room) do
    "#{prefix} #{@rpl_endofnames} #{nick} #{room} :End of /NAMES list."
  end

  def host do
    @server_host
  end

  def prefix do
    ":#{host}"
  end

end
