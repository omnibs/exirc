defmodule ExircdTest do
  use ExUnit.Case

  setup do
    UserRegistry.destroy
    RoomRegistry.destroy
  end

  test "registering a port initialzied but does not set a nick for user" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    assert(is_nil(User.nick(pid)))
  end

  test "registering a port initialzied retains passed in port" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    assert(User.port(pid) == List.first(:erlang.ports))
  end

  test "registering a nick for a user works when available" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    status = CommandDelegator.process("NICK jeff", pid)
    assert(status == :ok)

    receive do
      _-> flunk("shouldn't get any messages right now")
    after 500 -> :ok end
  end

  test "registering a nick for a user is a noop when the same" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    NickChangeProcessor.change_nick(pid, "steve")
    status = CommandDelegator.process("NICK steve", pid)
    assert(status == :noop)
  end

  test "registering a nick for a user errors when taken" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    NickChangeProcessor.change_nick(User.new, "fred")
    status = CommandDelegator.process("NICK fred", pid)
    assert(status == :error)

    assert_msg "#{Msgformat.prefix} 433 * fred :Nickname is already in use."
  end

  test "changing nickname should notify self" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    :ok = CommandDelegator.process("NICK durian", user1)
    
    ignore_msgs(4)

    assert_msg "#{Msgformat.prefix} fred!~realname@hi NICK :durian"
  end

  test "sending USER command with bit 3 unset updates user info and is visible" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    nick = "MyNick"
    User.set_nick(pid, nick)
    CommandDelegator.process("USER #{nick} 0 * :My real name", pid)
    assert(User.name(pid) == "My real name")
    assert(User.invisible?(pid) == false)
  end

  test "sending USER command with bit 3 updates user info and sets invisible" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    nick = "MyNick"
    User.set_nick(pid, nick)
    CommandDelegator.process("USER #{nick} 8 * :My real name", pid)
    assert(User.name(pid) == "My real name")
    assert(User.invisible?(pid) == true)
  end

  test "welcomes users when nick comes first" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    assert_msg ":localhost 001 fred :Welcome to localhost"
    assert_msg ":localhost 002 fred :Your host is exirc running version 16.10.07"
    assert_msg ":localhost 003 fred :This server was created 2016-10-07"
    assert_msg ":localhost 004 fred exircd 16.10.07 oiv r\""
  end

  test "welcomes users when info comes first" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("USER hi hi * :realname", user1)
    CommandDelegator.process("NICK fred", user1)

    assert_msg ":localhost 001 fred :Welcome to localhost"
    assert_msg ":localhost 002 fred :Your host is exirc running version 16.10.07"
    assert_msg ":localhost 003 fred :This server was created 2016-10-07"
    assert_msg ":localhost 004 fred exircd 16.10.07 oiv r\""
  end

  test "user to user messaging" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    user2 = UserRegistry.register(List.last(:erlang.ports), self)
    CommandDelegator.process("USER name fakehost * :realname", user2)
    CommandDelegator.process("NICK james", user2)
    CommandDelegator.process("PRIVMSG fred :hey there", user2)

    ignore_msgs(8) # ignore welcome for 2 users

    assert_msg "#{Msgformat.prefix} :james!~realname@fakehost PRIVMSG fred :hey there"
  end

  test "joining empty room" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    ignore_msgs(4)

    CommandDelegator.process("JOIN #room1", user1)

    assert_msg ":fred!~realname@hi JOIN #room1 * :realname"
    assert_msg ":localhost 353 fred = #room1 :fred"
    assert_msg ":localhost 366 fred #room1 :End of /NAMES list."
    assert_mailbox_empty
  end

  test "joining room with user" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)
    CommandDelegator.process("JOIN #room1", user1)

    user2 = UserRegistry.register(List.last(:erlang.ports), self)
    CommandDelegator.process("NICK george", user2)
    CommandDelegator.process("USER hi hi * :realname", user2)
    CommandDelegator.process("JOIN #room1", user2)
    
    ignore_msgs(4+3+4)
    assert_msg ":george!~realname@hi JOIN #room1 * :realname"
    assert_msg ":george!~realname@hi JOIN #room1 * :realname"
    assert_msg ":localhost 353 george = #room1 :fred george"
    assert_msg ":localhost 366 george #room1 :End of /NAMES list."
    assert_mailbox_empty
  end

  test "send message to room" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)
    CommandDelegator.process("JOIN #room1", user1)

    user2 = UserRegistry.register(List.last(:erlang.ports), self)
    CommandDelegator.process("NICK george", user2)
    CommandDelegator.process("USER hi hi * :realname", user2)
    CommandDelegator.process("JOIN #room1", user2)
    CommandDelegator.process("PRIVMSG #room1 :hey room", user1)

    ignore_msgs(4 + 3 + 4 + 1 + 3) # ignore welcome for 2 users

    assert_msg "#{Msgformat.prefix} :fred!~realname@hi PRIVMSG #room1 :hey room"
    # is this right? idk
    assert_msg "#{Msgformat.prefix} :fred!~realname@hi PRIVMSG #room1 :hey room"
    assert_mailbox_empty
  end

  test "detects nickname is already in use and notifies user" do
      
  end

  test "channel messages echo for all users except the sender" do
    
  end

  defp ignore_msgs(count, results  \\ [])
  defp ignore_msgs(0, results) do
    results
  end
  defp ignore_msgs(count, results) do
    msg = receive do
      x -> x
    after 500 -> 
      IO.inspect results
      flunk("timed out ignoring message, #{count} left to ignore")
    end
    ignore_msgs(count-1, [msg | results])
  end

  defp assert_msg(msg) do
    receive do
      {_, {:message, actual_msg}} ->
        assert msg == actual_msg
    after 500 -> flunk("timed out") end
  end

  defp assert_mailbox_empty do
    receive do
      x -> flunk("shouldn't have received msg #{inspect(x)}")
    after 100 -> nil end
  end
end
