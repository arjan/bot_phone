defmodule BotPhone.Hook do
  use GenServer
  require Logger

  alias BotPhone.{Dialer, Logic}
  alias ElixirALE.GPIO

  @poll 100
  @port 15

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def open? do
    if Process.whereis(__MODULE__) != nil do
      GenServer.call(__MODULE__, :open)
    else
      false
    end
  end

  defmodule State do
    defstruct open: nil, port: nil
  end

  def init(_) do
    Logger.warn("Hook started")

    {:ok, port} = GPIO.start_link(@port, :input)
    {:ok, %State{port: port}, 100}
  end

  def handle_call(:open, _from, state) do
    {:reply, state.open, state, @poll}
  end

  def handle_info(:timeout, state) do
    open = GPIO.read(state.port) == 0

    if open != state.open and !Dialer.dialing?() do
      if open do
        Logger.warn("-> Pickup")
        Logic.pickup()
      else
        Logger.warn("<- Hangup")
        Logic.hangup()
      end
    end

    {:noreply, %State{state | open: open}, @poll}
  end
end
