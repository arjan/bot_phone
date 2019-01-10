defmodule BotPhone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  require Logger

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotPhone.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  def children("host") do
    [
      BotPhone.Audio,
      {BotPhone.Client, Application.fetch_env!(:bot_phone, :bot_config)}
    ]
  end

  def children(_) do
    [ntp_child(), BotPhone.Dialer, BotPhone.Hook] ++ children("host")
  end

  def ntp_child() do
    worker(
      SystemRegistry.Task,
      [[:state, :network_interface, "wlan0", :ipv4_address], &init_network/1]
    )
  end

  def init_network(delta) do
    Logger.info("network initialized - init_network #{inspect(delta)}")
    Nerves.Time.restart_ntpd()
  end
end
