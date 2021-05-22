defmodule Chexx.PGN do
  def decode(pgn) do
    lines =
      String.split(pgn, "\n", trim: true)
      |> Enum.map(&String.trim/1)

    {_tags, movetexts} = Enum.split_with(lines, &String.starts_with?(&1, "["))

    plies =
      movetexts
        |> Enum.map(&String.replace(&1, ~r/;.*/, ""))
        |> Enum.map(&String.replace(&1, ~r/\{.*\}/, ""))
        |> Enum.flat_map(&String.split(&1, ~r/\d+\./, trim: true))
        |> Enum.map(&String.trim/1)
        |> Enum.flat_map(&String.split(&1, " ", trim: true))

    status =
      Enum.at(plies, -1)
      |> case do
        "1-0" -> :white_wins
        "0-1" -> :black_wins
        "1/2-1/2" -> :draw
      end

    plies = Enum.drop(plies, -1)

    Chexx.start_game()
    |> Chexx.plies(plies)
    |> case do
      {:ok, game} ->
        {:ok, %{game | status: status}}
      err -> err
    end
  end
end
