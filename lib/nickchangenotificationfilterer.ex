defmodule NickChangeNotificationFilterer do
  def filter_users_that_can_receive_a_notification(users) do
    notify_clients = users
    |> Enum.filter(fn user -> Map.has_key?(user, :info) end)
    |> Enum.map(fn user -> {user.client, Users.get_mask(user)} end)
  end
end
