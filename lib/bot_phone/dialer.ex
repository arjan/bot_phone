defmodule BotPhone.Dialer do
  use GenServer
  require Logger

  @port 14
  @debounce 80
  @timeout 200

  alias BotPhone.{Hook, Logic}
  alias ElixirALE.GPIO

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def dialing? do
    GenServer.call(__MODULE__, :dialing)
  end

  defmodule State do
    defstruct port: nil, dialing: false, last_edge: 0, pulse: 0
  end

  def init(_) do
    Logger.warn("Dialer started")

    {:ok, port} = GPIO.start_link(@port, :input)
    GPIO.set_int(port, :falling)

    {:ok, %State{port: port}, 0}
  end

  def handle_call(:dialing, _from, state) do
    {:reply, state.dialing, state, @timeout}
  end

  def handle_info({:gpio_interrupt, _, _}, state) do
    if Hook.open?() do
      t = now()

      if t - state.last_edge < @debounce do
        # ignore
        {:noreply, state, @timeout}
      else
        # handle
        {:noreply, %State{state | dialing: true, last_edge: t, pulse: state.pulse + 1}, @timeout}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info(:timeout, %{dialing: false} = state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.warn("Done: #{state.pulse}")
    Logic.digit(state.pulse)
    {:noreply, %State{state | dialing: false, pulse: 0}}
  end

  defp now() do
    :erlang.system_time(:millisecond)
  end
end
