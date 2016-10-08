defmodule User do
  defstruct nick: nil, port: nil, mask: nil, output: nil, host: nil, name: nil, flags: %{}, agent: nil
  @type t :: %__MODULE__{
    nick: String.t,
    port: port(),
    mask: String.t,
    output: pid(),
    host: String.t,
    name: String.t,
    flags: %{},
    agent: pid()
  }

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
    Agent.get(pid, fn user -> user.flags[:invisible] end)
  end

  @spec mask(pid()) :: String.t
  def mask(pid) do
    Agent.get(pid, fn user ->
      user.mask
    end)
  end

  @spec is_welcome?(pid()) :: Boolean
  def is_welcome?(pid) do
    Agent.get(pid, fn user ->
      user.name && user.nick
    end)
  end

  @spec output(pid()) :: pid()
  def output(pid) do
    Agent.get(pid, fn user -> user.output end)
  end

  @spec set_nick(pid(), String.t) :: atom()
  def set_nick(pid, nick) do
    Agent.update(pid, fn user -> 
      mask = "#{nick}!~#{user.name}@#{user.host}"
      %{user | nick: to_string(nick), mask: mask} 
    end)
  end

  @spec set_info(pid(), String.t) :: atom()
  def set_info(pid, info) do
    Agent.update(pid,
      fn user ->
        [_username, host_or_mode, _, ":" <> name] = String.split(info, " ", parts: 4)
        host = host_or_default(host_or_mode)
        mask = "#{user.nick}!~#{name}@#{host}"

        %{user |
          name: name,
          host: host,
          flags: Map.put(user.flags, :invisible, make_invisible?(host_or_mode)),
          mask: mask
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
      {_mode, _} ->
        "something.something.example.com"
    end
  end

end
