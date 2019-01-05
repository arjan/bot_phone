defmodule BotPhoneTest do
  use ExUnit.Case
  doctest BotPhone

  test "greets the world" do
    assert BotPhone.hello() == :world
  end
end
