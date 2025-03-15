defmodule GramexTest do
  use ExUnit.Case
  doctest Gramex

  test "greets the world" do
    assert Gramex.hello() == :world
  end
end
