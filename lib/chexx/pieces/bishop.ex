defmodule Chexx.Pieces.Bishop do
  alias Chexx.Square
  alias Chexx.Ply

  @enforce_keys [:color]
  defstruct [:color]

  def white do
    %__MODULE__{color: :white}
  end

  def black do
    %__MODULE__{color: :black}
  end

  def possible_bishop_moves(piece, source) do
    bishop_movements(source)
    |> Enum.map(fn destination ->
      Ply.single_touch(piece, source, destination)
    end)
  end

  def possible_bishop_sources(piece, destination) do
    bishop_movements(destination)
    |> Enum.map(fn source ->
      Ply.single_touch(piece, source, destination)
    end)
  end

  defp bishop_movements(around) do
    for distance <- 1..7, direction <- [:up_right, :down_right, :down_left, :up_left] do
      Square.move_direction(around, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defimpl Chexx.Piece do
    def to_symbol(%{color: :white}), do: "♗"
    def to_symbol(%{color: :black}), do: "♝"
    def moves_from(piece, square), do: Chexx.Pieces.Bishop.possible_bishop_moves(piece, square)
    def moves_to(piece, square), do: Chexx.Pieces.Bishop.possible_bishop_sources(piece, square)
    def type(_piece), do: :bishop
    def color(%{color: color}), do: color
  end
end
