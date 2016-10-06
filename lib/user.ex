defmodule User do
  defstruct nick: nil, port: nil, mask: nil, output: nil, host: nil, name: nil, flags: %{}, agent: nil

  @spec new :: pid()
  def new(opts \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %{%__MODULE__{} | agent: self,
                                                    nick: opts[:nick],
                                                    port: opts[:port],
                                                    mask: opts[:mask],
                                                    output: opts[:output],
                                                    host: opts[:host],
                                                    name: opts[:name],
                                                    flags: opts[:flag] || %{},
                                         }
                                  end)
    pid
  end

  @spec data(pid()) :: %User{}
  def data(pid) do
    Agent.get(pid, fn user -> user end)
  end

  @spec nick(pid()) :: String.t
  def nick(pid) do
    Agent.get(pid, fn user -> user.nick end)
  end

  @spec port(pid()) :: port()
  def port(pid) do
    Agent.get(pid, fn user -> user.port end)
  end

  @spec name(pid()) :: String.t
  def name(pid) do
    Agent.get(pid, fn user -> user.name end)
  end

  @spec invisible?(pid()) :: Boolean
  def invisible?(pid) do
    Agent.get(pid, fn user -> false end)
  end

  @spec mask(pid()) :: String.t
  def mask(pid) do
    Agent.get(pid, fn user ->
      "#{user.nick}!~#{user.name}@#{user.host}"
    end)
  end

  @spec is_welcome?(pid()) :: Boolean
  def is_welcome?(pid) do
    Agent.get(pid, fn user ->
      user.info && user.nick
    end)
  end

  @spec output(pid()) :: pid()
  def output(pid) do
    Agent.get(pid, fn user -> user.output end)
  end

  @spec set_nick(pid(), String.t) :: atom()
  def set_nick(pid, nick) do
    Agent.update(pid, fn user -> %{user | nick: to_string(nick)} end)
  end

  @spec set_info(pid(), String.t) :: atom()
  def set_info(pid, info) do
    Agent.update(pid,
      fn user ->
        [username, host_or_mode, _, ":" <> name] = String.split(info, " ", parts: 4)

        %{user |
          name: name,
          host: host_or_default(host_or_mode),
          flags: Map.put(user.flags, :invisible, make_invisible?(host_or_mode))
        }
      end
    )
  end

  @spec destroy(pid()) :: atom()
  def destroy(pid) do
    Agent.stop(pid)
  end

  defp make_invisible?(host_or_mode) do
    case Integer.parse(host_or_mode) do
      :error ->
        false
      {mode, _} ->
        [invisible | rest] = Integer.digits(mode, 2)
        invisible == 1
    end
  end

  defp host_or_default(host_or_mode) do
    case Integer.parse(host_or_mode) do
      :error ->
        host_or_mode
      {mode, _} ->
        "something.something.example.com"
    end

  end

end
