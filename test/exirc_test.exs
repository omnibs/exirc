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
    pid = CommandDelegator.new_user(:fake_port)
    assert(is_nil(User.nick(pid)))
  end

  test "registering a port initialzied retains passed in port" do
    pid = CommandDelegator.new_user(:fake_port)
    assert(User.port(pid) == :fake_port)
  end

  test "registering a nick for a user works when available" do
    CommandDelegator.new_user(:fake_port)
    status = CommandDelegator.process("NICK jeff", :fake_port)
    assert(status == :ok)
  end

  test "registering a nick for a user is a noop when the same" do
    pid = CommandDelegator.new_user(:fake_port)
    NickChangeProcessor.change_nick(pid, "steve")
    status = CommandDelegator.process("NICK steve", :fake_port)
    assert(status == :noop)
  end

  test "registering a nick for a user errors when taken" do
    CommandDelegator.new_user(:fake_port)
    NickChangeProcessor.change_nick(User.new, "fred")
    status = CommandDelegator.process("NICK fred", :fake_port)
    assert(status == :error)
  end


end
