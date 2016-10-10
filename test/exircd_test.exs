defmodule ExircdTest do
  use ExUnit.Case

  setup do
    UserRegistry.destroy
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

    receive do
      {_, {:message, message}} ->
        assert "#{Msgformat.prefix} 433 * fred :Nickname is already in use." == message
    after 500 -> flunk("timed out") end
  end

  test "changing nickname should notify self" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    :ok = CommandDelegator.process("NICK durian", user1)
    
    ignore_msgs(4)

    receive do
      {_, {:message, message}} ->
        assert "#{Msgformat.prefix} fred!~realname@hi NICK :durian" == message
    after 500 -> flunk("timed out") end
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

    receive do
      {_, {:message, message}} ->
        assert ":localhost 001 fred :Welcome to localhost" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 002 fred :Your host is exirc running version 16.10.07" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 003 fred :This server was created 2016-10-07" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 004 fred exircd 16.10.07 oiv r\"" == message
    after 500 -> flunk("timed out") end
  end

  test "welcomes users when info comes first" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("USER hi hi * :realname", user1)
    CommandDelegator.process("NICK fred", user1)

    receive do
      {_, {:message, message}} ->
        assert ":localhost 001 fred :Welcome to localhost" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 002 fred :Your host is exirc running version 16.10.07" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 003 fred :This server was created 2016-10-07" == message
    after 500 -> flunk("timed out") end
    receive do
      {_, {:message, message}} ->
        assert ":localhost 004 fred exircd 16.10.07 oiv r\"" == message
    after 500 -> flunk("timed out") end
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

    receive do
      {_, {:message, message}} ->
        assert "#{Msgformat.prefix} :james!~realname@fakehost PRIVMSG fred :hey there" == message
    end
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

    ignore_msgs(8) # ignore welcome for 2 users

    receive do
      {_, {:message, message}} ->
        assert "#{Msgformat.prefix} :fred!~realname@hi PRIVMSG #room1 :hey room" == message
    after 500 -> flunk("timed out") end
  end

  test "detects nickname is already in use and notifies user" do
    
  end

  test "channel messages echo for all users except the sender" do
    
  end

  defp ignore_msgs(0) do
  end
  defp ignore_msgs(count) do
    receive do
      _ -> nil
    after 500 -> flunk("timed out ignoring message, #{count} left to ignore") end
    ignore_msgs(count-1)
  end
end
