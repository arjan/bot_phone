defmodule BotPhone.GpioManager do
  use GenServer
  require Logger

  alias ElixirALE.GPIO

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    ports =
      for p <- [:pickup, :digit] do
        {:ok, pid} = GPIO.start_link(port(p), :input)
        GPIO.set_int(pid, :both)
        {p, pid}
      end
      |> Map.new()

    # for p <- [:pickup, :ground, :digit] do
    #   {:ok, pid} = GPIO.start_link(port(p), :input)
    #   GPIO.set_int(pid, :both)
    # end

    {:ok, %{ports: ports, pickup_flag: false}}
  end

  def handle_info({:gpio_interrupt, 15, :falling}, state) do
    IO.puts("15 falling")
    Process.send_after(self(), :check_pickup, 100)
    {:noreply, %{state | pickup_flag: true}}
  end

  def handle_info({:gpio_interrupt, 15, :rising}, state) do
    IO.puts("15 rising")
    Process.send_after(self(), :check_hangup, 100)
    {:noreply, %{state | pickup_flag: true}}
  end

  def handle_info(:check_pickup, state) do
    if GPIO.read(state.ports.pickup) == 0 and state.pickup_flag do
      Logger.warn("picked up")
    end

    {:noreply, %{state | pickup_flag: false}}
  end

  def handle_info(:check_hangup, state) do
    if GPIO.read(state.ports.pickup) == 1 and state.pickup_flag do
      Logger.warn("hung up")
    end

    {:noreply, %{state | pickup_flag: false}}
  end

  def handle_info({:gpio_interrupt, 14, :rising}, state) do
    {:noreply, %{state | pickup_flag: false}}
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "message1")

    {:noreply, state}
  end

  def port(:pickup), do: 15
  def port(:digit), do: 14
end
