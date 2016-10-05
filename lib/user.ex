defmodule User do
  defstruct nick: nil, port: nil, mask: nil, output: nil, info: "", flags: %{}, agent: nil

  @spec new :: pid()
  def new(opts \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %{%__MODULE__{} | agent: self,
                                                    nick: opts[:nick],
                                                    port: opts[:port],
                                                    mask: opts[:mask],
                                                    output: opts[:output],
                                                    info: opts[:info] || "",
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

  @spec info(pid()) :: String.t
  def info(pid) do
    Agent.get(pid, fn user -> user.info end)
  end

  @spec mask(pid()) :: String.t
  def mask(pid) do
    Agent.get(pid, fn user ->
      [name, _] = String.split(user.info, " ", parts: 2)
      "#{user.nick}!~#{name}@something.something"
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
    Agent.update(pid, fn user -> %{user | info: to_string(info)} end)
  end

  @spec destroy(pid()) :: atom()
  def destroy(pid) do
    Agent.stop(pid)
  end

end
