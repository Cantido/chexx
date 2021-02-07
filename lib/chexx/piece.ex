defmodule Chexx.Piece do
  @moduledoc """
  A piece type and color.
  """
  import Chexx, only: [
    is_color: 1,
    is_piece: 1
  ]

  @enforce_keys [
    :type,
    :color
  ]
  defstruct [
    :type,
    :color
  ]

  def new(type, color) when is_piece(type) and is_color(color) do
    %__MODULE__{type: type, color: color}
  end
end
