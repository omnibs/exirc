defmodule User do
  defstruct nick: nil, port: nil, info: "", flags: %{}, agent: nil, output: nil

  @spec new :: pid()
  def new(opts \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %{%__MODULE__{} | agent: self,
                                                    nick: opts[:nick],
                                                    port: opts[:port],
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