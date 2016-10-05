defmodule RoomRegistry do

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def register(channel, writer) do
    Agent.get_and_update(__MODULE__, fn registry ->
      pid = Room.new(%{channel: channel, output: writer})
      {pid, Map.put(registry, channel, pid)}
    end)
  end

  def unregister(pid) do
    Agent.update(__MODULE__, fn registry ->
      data = Room.data(pid)
      Map.pop(registry, data.channel)
    end)
  end

  def destroy do
    # Agent.stop(__MODULE__)
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

end
