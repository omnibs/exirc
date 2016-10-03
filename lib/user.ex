defmodule User do
  defstruct nick: nil, port: nil, flags: %{}, agent: nil

  def new(opts \\ %{flags: %{}}) do
    {:ok, pid} = Agent.start_link(fn -> %{%User{} | agent: self, nick: opts[:nick], port: opts[:port],  flags: opts[:flag] } end)
    pid
  end

  def data(pid) do
    Agent.get(pid, fn user -> user end)
  end

  def nick(pid) do
    Agent.get(pid, fn user -> user.nick end)
  end

  def port(pid) do
    Agent.get(pid, fn user -> user.port end)
  end

  def set_nick(pid, nick) do
    Agent.update(pid, fn user -> %{user | nick: nick} end)
  end

  def destroy(pid) do
    Agent.stop(pid)
  end

end