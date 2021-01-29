defmodule ChexxTest do
  use ExUnit.Case
  doctest Chexx

  test "greets the world" do
    assert Chexx.hello() == :world
  end
end
