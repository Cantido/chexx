defmodule Chexx.Touch do
  @moduledoc """
  The act of touching and moving a piece.
  Encodes a start square and end square.
  """

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

  def new(source, destination, piece) do
    %__MODULE__{
      source: source,
      destination: destination,
      piece: piece
    }
  end

  def new(map) when is_map(map) do
    params = Map.take(map, [
      :source,
      :destination,
      :piece
    ])
    struct(__MODULE__, params)
  end
end
