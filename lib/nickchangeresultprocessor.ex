defmodule NickChangeResultProcessor do
	require Logger

	def process({:ok, user, old_nick}, client, users_by_channel) do
		Logger.info "Accepted nick change from #{old_nick} to #{user.nick}"
		notify_nick_change(user, old_nick, users_by_channel)
	end
	def process({:error, user}, client) do
		Logger.info "Rejected nick change"
		[Msgformat.nick_in_use(client, user.nick)]
	end
	def process(:noop, client), do: []

	defp notify_nick_change(_, nil, __), do: []
	defp notify_nick_change(user, old_nick, users_by_channel) do
		self = %{user | nick: old_nick}
		users = NickChangeNotificationFilterer.filter_users_that_can_receive_a_notification([self])

		Logger.info "Notifyinng #{inspect(users)} of #{old_nick}'s nick change"

		for {c, mask} <- users,
			do: {c, ":" <> mask <> " NICK :" <> user.nick}
	end
end


