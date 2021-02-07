defmodule Chexx.Touch do
  @moduledoc """
  The act of touching and moving a piece.
  Encodes a start square and end square.
  """

  def new(source, destination, piece) do
    %{
      source: source,
      destination: destination,
      piece: piece
    }
  end

  def new(map) when is_map(map) do
    Map.take(map, [
      :source,
      :destination,
      :piece
    ])
  end
end
