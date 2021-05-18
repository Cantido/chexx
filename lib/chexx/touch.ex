defmodule Chexx.Touch do
  @moduledoc """
  The act of touching and moving a piece.
  Encodes a start square and end square.
  """

  alias Chexx.Square
  alias Chexx.Piece

  @type t() :: %__MODULE__{
    source: Chexx.Square.t(),
    destination: Chexx.Square.t(),
    piece: Chexx.Piece.t()
  }

  @enforce_keys [
    :source,
    :destination,
    :piece
  ]
  defstruct [
    :source,
    :destination,
    :piece
  ]

  @spec new(Chexx.Square.t(), Chexx.Square.t(), Chexx.Piece.t()) :: t()
  def new(%Square{} = source, %Square{} = destination, %Piece{} = piece) do
    %__MODULE__{
      source: source,
      destination: destination,
      piece: piece
    }
  end

  @spec new(%{source: Chexx.Square.t(), destination: Chexx.Square.t(), piece: Chexx.Piece.t()}) :: t()
  def new(map) when is_map(map) do
    params = Map.take(map, [
      :source,
      :destination,
      :piece
    ])
    struct(__MODULE__, params)
  end
end
