defmodule Room do
  require Logger
  defstruct channel: nil, output: nil, agent: nil, users: []

  @spec new :: pid()
  def new(opts \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %{%__MODULE__{} | agent: self,
                                                    channel: opts[:channel],
                                                    output: opts[:output],
                                                    users: opts[:users] || [],
                                         }
                                  end)
    pid
  end

  @spec data(pid()) :: %Room{}
  def data(pid) do
    Agent.get(pid, fn room -> room end)
  end

  @spec channel(pid()) :: String.t
  def channel(pid) do
    Agent.get(pid, fn room -> room.channel end)
  end

  @spec output(pid()) :: pid()
  def output(pid) do
    Agent.get(pid, fn room -> room.output end)
  end

  @spec set_output(pid(), pid()) :: no_return
  def set_output(pid, output) do
    Agent.update(pid, fn room -> %Room{ room | output: output } end)
  end

  @spec users(pid()) :: List
  def users(pid) do
    Agent.get(pid, fn room -> room.users end)
  end

  @spec add_user(pid(), pid()) :: no_return
  def add_user(pid, user_agent) do
    Agent.update(pid, fn room -> %Room{ room | users: [user_agent | room.users] } end)
  end

  @spec remove_user(pid(), pid()) :: no_return
  def remove_user(pid, user_agent) do
    Agent.update(pid, fn room -> %Room{ room | users: List.delete(room.users, user_agent) } end)
  end

  @spec destroy(pid()) :: atom()
  def destroy(pid) do
    Agent.stop(pid)
  end

end
