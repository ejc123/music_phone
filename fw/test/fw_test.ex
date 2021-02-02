defmodule FwTest do
  use ExUnit.Case
  doctest FwTest

  test "greets the world" do
    assert FwTest.hello() == :world
  end
end
