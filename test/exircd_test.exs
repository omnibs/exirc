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

  test "sending message" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER hi hi * :realname", user1)

    user2 = UserRegistry.register(List.last(:erlang.ports), self)
    CommandDelegator.process("USER name fakehost * :realname", user2)
    CommandDelegator.process("NICK james", user2)
    CommandDelegator.process("PRIVMSG fred :hey there", user2)

    receive do
      {_, {:message, message}} ->
        assert ":james!~realname@fakehost PRIVMSG fred :hey there" == message
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

    receive do
      {_, {:message, message}} ->
        assert ":fred!~realname@fakehost PRIVMSG #room1 :hey room" == message
    end

  end

end
