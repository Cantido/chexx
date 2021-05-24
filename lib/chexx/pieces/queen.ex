defmodule Chexx.Pieces.Queen do
  alias Chexx.Ply
  alias Chexx.Square

  @enforce_keys [:color]
  defstruct [:color]

  def possible_queen_moves(%__MODULE__{color: player}, source) do
    queen_movements(source)
    |> Enum.map(fn destination ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination)
    end)
  end

  def possible_queen_sources(%__MODULE__{color: player}, destination) do
    queen_movements(destination)
    |> Enum.map(fn source ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination)
    end)
  end

  defp queen_movements(source) do
    for distance <- 1..7, direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end
end
