defmodule Channel do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, {%{}}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def get_channel_mates(%{client: port}) do
    []
  end
end
