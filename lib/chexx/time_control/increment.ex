defmodule Chexx.TimeControl.Increment do
  alias Chexx.Color

  @enforce_keys [
    :starting_ms,
    :increment_ms
  ]
  defstruct [
    starting_ms: nil,
    increment_ms: nil,
    player_ms_remaining: %{},
    last_switch: nil,
    current_player: :white
  ]

  defimpl Chexx.TimeControl do
    def start(tc, timestamp) do
      %{tc |
        player_ms_remaining: %{white: tc.starting_ms},
        last_switch: timestamp,
        current_player: :white
      }
    end

    def switch(tc, timestamp) do
      previous_player = tc.current_player
      next_player = Color.opponent(tc.current_player)
      turn_duration = DateTime.diff(timestamp, tc.last_switch, :millisecond)

      tc =
        tc
        |> add_time(tc.current_player, -turn_duration)
        |> add_time(next_player, tc.starting_ms)

      tc =
        %{tc |
          last_switch: timestamp,
          current_player: next_player
        }

      if tc.player_ms_remaining[previous_player] < 0 do
        {:flag_fall, previous_player, tc}
      else
        {:ok, increment(tc, previous_player)}
      end
    end

    def flag_fall?(tc, player, timestamp) do
      if tc.current_player == player do
        turn_duration = DateTime.diff(timestamp, tc.last_switch, :millisecond)

        (tc.player_ms_remaining[player] - turn_duration) < 0
      else
        tc.player_ms_remaining[player] < 0
      end
    end

    defp increment(tc, player) do
      add_time(tc, player, tc.increment_ms)
    end

    defp add_time(tc, player, ms) do
      %{tc |
        player_ms_remaining: Map.update(tc.player_ms_remaining, player, ms, &(&1 + ms)),
      }
    end

    def time_remaining(tc, player, timestamp, time_unit) do
      remaining_before_turn = System.convert_time_unit(tc.player_ms_remaining[player], :millisecond, time_unit)

      if tc.current_player == player do
        turn_duration = DateTime.diff(timestamp, tc.last_switch, time_unit)

        (remaining_before_turn - turn_duration)
      else
        remaining_before_turn
      end
    end
  end
end
