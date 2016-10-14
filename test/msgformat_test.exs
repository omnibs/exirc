defmodule MsgformatTest do
  use ExUnit.Case

  test "doesnt chunk below 460 chars" do
    assert Msgformat.names(["jasnira"], "jasnira", "#asd")
      == [":localhost 353 jasnira = #asd :jasnira"]
  end

  test "chunks above 460 chars" do
    nicks = [
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
      "123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789","123456789",
    ]
    msgs = Msgformat.names(nicks, "jasnira", "#asd")
    assert length(msgs) == 2
  end
end
