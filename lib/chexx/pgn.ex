defmodule Chexx.PGN do
  alias Chexx.PGN.Parser

  def parse!(pgn) do
    games_data = Parser.parse!(pgn)


    Enum.map(games_data, &build_game/1)
  end

  defp build_game(data) do
    status =
      case data.tags["Result"] do
        "1-0" -> :white_wins
        "0-1" -> :black_wins
        "1/2-1/2" -> :draw
        "*" -> :in_progress
      end

    game =
      Chexx.start_game()

    game =
      Enum.reduce(data.moves, game, fn move, game ->
        {:ok, game} = Chexx.move(game, Chexx.AlgebraicNotation.parse(move.white_move))
        if Map.has_key?(move, :black_move) do
          {:ok, game} = Chexx.move(game, Chexx.AlgebraicNotation.parse(move.black_move))
          game
        else
          game
        end
      end)


    %{game | status: status}
  end
end
