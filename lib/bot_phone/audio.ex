defmodule BotPhone.Audio do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def play(file) do
    GenServer.cast(__MODULE__, {:play, file})
  end

  def init([]) do
    # set minijack output
    :os.cmd('amixer cset numid=3 1')
    # set volume to 100%
    :os.cmd('amixer sset PCM,0 100%')

    {:ok, nil}
  end

  def handle_cast({:play, file}, state) do
    :os.cmd('mpg123 /mp3/#{file}.mp3')

    {:noreply, state}
  end
end
