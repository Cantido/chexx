defmodule Chexx.Pieces.Rook do
  alias Chexx.Ply
  alias Chexx.Square

  @enforce_keys [:color]
  defstruct [:color]

  def possible_rook_moves(%__MODULE__{color: player}, source) do
    rook_movements(source)
    |> Enum.map(fn destination ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination)
    end)
  end

  def possible_rook_sources(%__MODULE__{color: player}, destination) do
    rook_movements(destination)
    |> Enum.map(fn source ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination)
    end)
  end

  defp rook_movements(around) do
    for distance <- 1..7, direction <- [:up, :left, :down, :right] do
      Square.move_direction(around, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  defimpl Chexx.Piece do
    def to_string(%{color: :white}), do: "♖"
    def to_string(%{color: :black}), do: "♜"
    def moves_from(piece, square), do: Chexx.Pieces.Rook.possible_rook_moves(piece, square)
    def moves_to(piece, square), do: Chexx.Pieces.Rook.possible_rook_sources(piece, square)
    def type(_piece), do: :rook
    def color(%{color: color}), do: color
  end
end
