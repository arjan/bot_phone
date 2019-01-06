defmodule BotPhone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotPhone.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  def children("host") do
    [
      {BotPhone.Client, Application.fetch_env!(:bot_phone, :bot_config)}
    ]
  end

  def children(_) do
    [BotPhone.Audio, BotPhone.Dialer, BotPhone.Hook] ++ children("host")
  end
end
