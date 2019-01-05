defmodule BotPhone.Logic do
  alias BotPhone.Client

  def hangup do
    Client.leave()
  end

  def pickup do
    Client.join()
  end

  def digit(n) do
    Client.send_text(to_string(n))
  end
end
