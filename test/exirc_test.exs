defmodule ExircTest do
  use ExUnit.Case

  test "only nick and user allowed before booting finished" do
    booting = %{booting: true}
    booted = %{}
    assert IRC.allowed?("NICK ",booting)
    assert IRC.allowed?("USER ",booting)
    assert !IRC.allowed?("jasnira",booting)
    assert IRC.allowed?("jasnira", booted)
  end

  test "registering a port initialzied but does not set a nick for user" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    assert(is_nil(User.nick(pid)))
  end

  test "registering a port initialzied retains passed in port" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    assert(User.port(pid) == List.first(:erlang.ports))
  end

  test "registering a nick for a user works when available" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    status = CommandDelegator.process("NICK jeff", pid)
    assert(status == :ok)
  end

  test "registering a nick for a user is a noop when the same" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    NickChangeProcessor.change_nick(pid, "steve")
    status = CommandDelegator.process("NICK steve", pid)
    assert(status == :noop)
  end

  test "registering a nick for a user errors when taken" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    NickChangeProcessor.change_nick(User.new, "fred")
    status = CommandDelegator.process("NICK fred", pid)
    assert(status == :error)
  end

  test "sending USER command updates user info" do
    pid = IRC.new_user(List.first(:erlang.ports), self)
    status = CommandDelegator.process("USER :Real name", pid)
    assert(User.info(pid) == "Real name")
  end


end
