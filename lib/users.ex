defmodule Users do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, {%{},%{}}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def register(client) when is_port(client) do
    GenServer.cast(__MODULE__, {:register, client})
  end
  def create_user(nick, client) when is_port(client) do
    GenServer.call(__MODULE__, {:create_user, unwelcomed_user(nick, client)})
  end

  def get(user) do
    GenServer.call(__MODULE__, {:get, user})
  end

  def resolve_users(users) do
    GenServer.call(__MODULE__, {:resolve_users, users})
  end

  def change_nick(client, nick) when is_port(client) do
    GenServer.call(__MODULE__, {:change_nick, client, nick})
  end

  def update_info(client, info) when is_port(client) do
    GenServer.call(__MODULE__, {:update_info, client, info})
  end

  def mark_welcomed(user) do
    GenServer.call(__MODULE__, {:mark_welcomed, user})
  end

  def get_mask(user) do
    [name, _] = String.split(user.info, " ", parts: 2)
    "#{user.nick}!~#{name}@something.something"
  end

  # --- Callback methods
  def handle_cast({:register, client}, {nicks, clients}) do
    clients = Map.put(clients, client, unwelcomed_user(nil, client))

    {:noreply, {nicks, clients}}
  end
  def handle_call({:create_user, user}, _from, {nicks, clients} = state) do
    %{nick: nick, client: client} = user
    case Map.has_key?(nicks, nick) do
      false ->
        nicks = Map.put(nicks, nick, user)

        {nicks, clients} = remove_client({nicks, clients}, client)

        clients = Map.put(clients, client, user)

        {:reply, {:ok, user}, {nicks, clients}}
      true ->
        {:reply, :error, state}
    end
  end

  def handle_call({:get, user}, _from, state) do
    {:reply, get_user(state, user), state}
  end

  def handle_call({:resolve_users, users}, _from, state) do
    users = Enum.map(users, fn (x) -> get_user(state, x) end)
    {:reply, users, state}
  end

  def handle_call({:change_nick, client, nick}, _from, {nicks, clients} = state) do
    case Map.has_key?(nicks, nick) do
      false ->
        %{nick: old_nick} = user = get_user(state, client)
        user = Map.put(user, :nick, nick)
        {user, msgs} = check_welcome(user)

        # gotta match anything
        # if the user didn't have a nick before
        # nothing's gonna come out
        {_, nicks} = Map.pop(nicks, old_nick)
        nicks = Map.put(nicks, nick, user)
        clients = Map.put(clients, user.client, user)

        {:reply, {:ok, user, old_nick, msgs}, {nicks, clients}}
      true ->
        case get_user(state, client) do
          %{nick: _nick} ->
            {:reply, :noop, state}
          user ->
            {:reply, {:error, user}, state}
        end
    end
  end

  def handle_call({:update_info, user, info}, _from, {_nicks, _clients} = state) do
    user = get_user(state, user)
    {user, msgs} = check_welcome(user)

    state = update_user(state, user, fn old ->
      {old, Map.put(user, :info, info)}
    end)

    {:reply, {user, msgs} , state}
  end

  def handle_call({:mark_welcomed, user}, _from, state) do
    state = update_user(state, user, fn userdata ->
      {userdata, Map.put(userdata, :is_welcome, true)}
    end)
    {:reply, :ok, state}
  end

  # --- Helper methods
  defp check_welcome(user) do
    if !user.is_welcome
        && Map.has_key?(user, :nick)
        && Map.has_key?(user, :info) do
      {%{user | is_welcome: true}, [Msgformat.welcome(user.client, user)]}
    else
      {user, []}
    end
  end

  defp update_user({nicks, clients} = state, user, updatefn) do
    user = get_user(state, user)
    with {_, nicks} <- Map.get_and_update(nicks, user.nick, updatefn),
       {_, clients} <- Map.get_and_update(clients, user.client, updatefn),
       do: {nicks, clients}
  end

  defp get_user({_, clients}, client) when is_port(client) do
    Map.get(clients, client)
  end

  defp get_user({nicks, _}, nick) when is_binary(nick) do
    Map.get(nicks, nick)
  end

  defp remove_client({nicks, clients} = state, client) do
    case Map.has_key?(clients, client) do
      true ->
        {%{nick: nick}, clients} = Map.pop(clients, client)
        {_, nicks} = Map.pop(nicks, nick)
        {nicks, clients}
      false ->
        state
    end
  end

  defp unwelcomed_user(nick, client) do
    %{nick: nick, client: client, is_welcome: false}
  end
end
