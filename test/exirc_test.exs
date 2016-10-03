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
end
