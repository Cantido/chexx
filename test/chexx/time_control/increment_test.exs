defmodule Chexx.TimeControl.IncrementTest do
  use ExUnit.Case, async: true
  alias Chexx.TimeControl
  alias Chexx.TimeControl.Increment
  doctest Chexx.TimeControl.Increment

  test "switch/2 returns a flag_fall tuple after time is out" do
    {:flag_fall, :white, _tc} =
      TimeControl.start(
        %Increment{starting_ms: 1_000, increment_ms: 0},
        ~U[2021-05-24T12:00:00.000Z]
      )
      |> TimeControl.switch(~U[2021-05-24T12:00:01.001Z])
  end

  test "switching means time stops being consumed for the current player" do
    {:ok, _tc} =
      %Increment{starting_ms: 1_000, increment_ms: 0}
      |> TimeControl.start(~U[2021-05-24T12:00:00.000Z])
      |> TimeControl.switch(~U[2021-05-24T12:00:00.999Z])
  end

  test "each turn adds an increment of time after the turn" do
    {:ok, tc} =
      %Increment{starting_ms: 1_000, increment_ms: 1_000}
      |> TimeControl.start(~U[2021-05-24T12:00:00.000Z])
      |> TimeControl.switch(~U[2021-05-24T12:00:00.500Z])

    assert TimeControl.time_remaining(tc, :white, ~U[2021-05-24T12:00:00.500Z]) == 1_500
  end
end
