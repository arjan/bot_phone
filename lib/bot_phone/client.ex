defmodule BotPhone.Client do
  use GenServer
  require Logger

  alias BotPhone.{GoogleTTS, Audio}

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def join() do
    GenServer.call(__MODULE__, :join)
  end

  def leave() do
    GenServer.call(__MODULE__, :leave)
  end

  def send_text(n) do
    GenServer.call(__MODULE__, {:send_text, n})
  end

  ###

  defmodule State do
    defstruct [:config, :client_pid, :socket, :channel]
  end

  def init(config) do
    {:ok, client_pid} = PhoenixChannelClient.start_link()
    {:ok, %State{config: config, client_pid: client_pid}, {:continue, :connect}}
  end

  def handle_call({:send_text, _n}, _from, %State{channel: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:send_text, n}, _from, state) do
    {:ok, _} =
      PhoenixChannelClient.push_and_receive(
        state.channel,
        "user_action",
        %{type: "message", payload: n},
        100
      )

    {:reply, :ok, state}
  end

  def handle_call(:join, _from, %{socket: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:join, _from, state) do
    channel =
      PhoenixChannelClient.channel(state.socket, "bot:" <> state.config[:bot], %{
        user_id: state.config[:user_id]
      })

    {:ok, _result} = PhoenixChannelClient.join(channel)
    Logger.warn("joined")

    {:reply, :ok, %State{state | channel: channel}}
  end

  def handle_call(:leave, _from, %{socket: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:leave, _from, %{channel: nil} = state) do
    {:reply, {:error, :not_joined}, state}
  end

  def handle_call(:leave, _from, state) do
    {:ok, _} = PhoenixChannelClient.leave(state.channel)
    {:reply, :ok, %State{state | channel: nil}}
  end

  def handle_continue(:connect, state) do
    {:noreply, try_connect(state)}
  end

  def handle_info(:reconnect, state) do
    {:noreply, try_connect(state)}
  end

  def handle_info({"message", %{"payload" => %{"kind" => "audio", "url" => url}}}, state) do
    Logger.info("Play URL: #{url}")
    Audio.play(url)
    {:noreply, state}
  end

  def handle_info({"message", %{"payload" => %{"message" => message}}}, state) do
    {:ok, content} = GoogleTTS.synthesize(message)
    Logger.info("Play text: #{message}")
    Audio.play(content)
    {:noreply, state}
  end

  def handle_info({"emit", %{"event" => "mp3", "payload" => file}}, state) do
    Logger.info("Play: #{file}")

    Audio.play(file)
    {:noreply, state}
  end

  def handle_info({push, payload}, state) when is_binary(push) do
    Logger.info("→ push: #{push}")
    Logger.info("        #{inspect(payload)}")

    {:noreply, state}
  end

  defp try_connect(state) do
    with {:ok, socket} <-
           PhoenixChannelClient.connect(state.client_pid,
             host: state.config[:host],
             path: "/socket/websocket",
             params: %{},
             secure: true,
             heartbeat_interval: 30_000
           ) do
      Logger.warn("Connected.")
      %{state | socket: socket, channel: nil}
    else
      _ ->
        Logger.warn("Reconnect...")
        Process.send_after(self(), :reconnect, 3_000)
        state
    end
  end
end
