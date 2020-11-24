defmodule PhoneTest do
  use ExUnit.Case
  doctest Phone

  test "greets the world" do
    assert Phone.hello() == :world
  end
end
