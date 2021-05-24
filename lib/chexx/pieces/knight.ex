defmodule Chexx.Pieces.Knight do
  alias Chexx.Ply
  alias Chexx.Square

  @enforce_keys [:color]
  defstruct [:color]

  def possible_knight_moves(%__MODULE__{color: player}, source) do
    knight_movements(source)
    |> Enum.map(fn destination ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination, traverses: false)
    end)
  end

  def possible_knight_sources(%__MODULE__{color: player}, destination) do
    knight_movements(destination)
    |> Enum.map(fn source ->
      Ply.single_touch(%__MODULE__{color: player}, source, destination, traverses: false)
    end)
  end

  defp knight_movements(around) do
    [
      around |> Square.up(2) |> Square.right(),
      around |> Square.up(2) |> Square.left(),
      around |> Square.right(2) |> Square.up(),
      around |> Square.right(2) |> Square.down(),
      around |> Square.down(2) |> Square.right(),
      around |> Square.down(2) |> Square.left(),
      around |> Square.left(2) |> Square.up(),
      around |> Square.left(2) |> Square.down()
    ]
    |> Enum.filter(fn source ->
      Square.within?(source, 1..8, 1..8)
    end)
  end

  defimpl Chexx.Piece do
    def to_string(%{color: :white}), do: "♘"
    def to_string(%{color: :black}), do: "♞"
    def moves_from(piece, square), do: Chexx.Pieces.Knight.possible_knight_moves(piece, square)
    def moves_to(piece, square), do: Chexx.Pieces.Knight.possible_knight_sources(piece, square)
    def type(_piece), do: :knight
    def color(%{color: color}), do: color
  end
end
