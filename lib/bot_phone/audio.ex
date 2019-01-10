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
    :os.cmd('mpg123 #{resolve(file)}')

    {:noreply, state}
  end

  defp resolve("/" <> _ = file), do: file
  defp resolve("http:" <> _ = file), do: file
  defp resolve("https:" <> _ = file), do: file

  defp resolve(file) when is_binary(file) do
    "/mp3/#{file}.mp3"
  end

  defp resolve(%{"audioContent" => content}) do
    File.write!("/tmp/audio.mp3", Base.decode64!(content))
    "/tmp/audio.mp3"
  end
end
