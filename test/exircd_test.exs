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

  test "sending USER command updates user info" do
    pid = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("USER name name host :Real name", pid)
    assert(User.info(pid) == "Real name")
  end

  @tag :skip
  test "race cond" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    User.set_info(user1, "hi hi")
    User.set_nick(user1, "oi")
    IO.inspect User.data(user1)
  end

  # @tag :skip
  test "sending message" do
    user1 = UserRegistry.register(List.first(:erlang.ports), self)
    CommandDelegator.process("NICK fred", user1)
    CommandDelegator.process("USER :hi hi", user1)

    user2 = UserRegistry.register(List.last(:erlang.ports), self)
    CommandDelegator.process("USER :test test", user2)
    CommandDelegator.process("NICK james", user2)
    CommandDelegator.process("PRIVMSG fred :hey there", user2)
    
    receive do
      {_, {:message, message}} ->
        assert "james!~test@something.something fred :-hey there" == message
    end

  end
end