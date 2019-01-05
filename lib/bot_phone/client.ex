defmodule BotPhone.Client do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def send_text(n) do
    GenServer.call(__MODULE__, {:send_text, n})
  end

  defmodule State do
    defstruct [:config, :client_pid, :socket, :channel]
  end

  def init(config) do
    {:ok, client_pid} = PhoenixChannelClient.start_link()
    {:ok, %State{config: config, client_pid: client_pid}, {:continue, :start}}
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

  def handle_continue(:start, state) do
    {:ok, socket} =
      PhoenixChannelClient.connect(state.client_pid,
        host: state.config[:host],
        path: "/socket/websocket",
        params: %{},
        secure: true,
        heartbeat_interval: 30_000
      )

    channel =
      PhoenixChannelClient.channel(socket, "bot:" <> state.config[:bot], %{
        user_id: state.config[:user_id]
      })

    {:ok, result} = PhoenixChannelClient.join(channel)
    IO.inspect(result, label: "result")

    {:noreply, %{state | socket: socket, channel: channel}}
  end

  def handle_info({"message", payload}, state) do
    Logger.warn("Message: #{payload["payload"]["message"]}")

    {:noreply, state}
  end

  def handle_info({push, _}, state) when is_binary(push) do
    {:noreply, state}
  end
end
