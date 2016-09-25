defmodule NickChangeNotificationFiltererTests do
	use ExUnit.Case

	test "filters out users that cant have a mask built for them" do
		input = [%{info: "asd dsa ddd aaa", client: 1, nick: "jasnira"}, %{}]
		output = NickChangeNotificationFilterer.filter_users_that_can_receive_a_notification(input)

		assert [{1, "jasnira!~asd@something.something"}] == output
	end
end