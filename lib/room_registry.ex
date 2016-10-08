defmodule RoomRegistry do

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def pid_from_channel(channel) do
    Agent.get_and_update(__MODULE__, fn registry ->
      if Map.has_key?(registry, channel) do
        {registry[channel], registry}
      else
        pid = Room.new(%{channel: channel})
        RoomOutput.start(pid)
        {pid, Map.put(registry, channel, pid)}
      end
    end)
  end

  def unregister(pid) do
    Agent.update(__MODULE__, fn registry ->
      data = Room.data(pid)
      Map.pop(registry, data.channel)
    end)
  end

  def destroy do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

end
