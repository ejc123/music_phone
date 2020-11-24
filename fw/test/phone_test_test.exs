defmodule PhoneTestTest do
  use ExUnit.Case
  doctest PhoneTest

  test "greets the world" do
    assert PhoneTest.hello() == :world
  end
end
