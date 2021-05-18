defmodule Chexx.Promotion do
  alias Chexx.Square
  alias Chexx.Piece

  @type t() :: %__MODULE__{
    source: Chexx.Square.t(),
    promoted_to: Chexx.Piece.t()
  }

  @enforce_keys [
    :source,
    :promoted_to
  ]
  defstruct [
    :source,
    :promoted_to
  ]

  @spec new(Chexx.Square.t(), Chexx.Piece.t()) :: t()
  def new(%Square{} = source, %Piece{} = promoted_to) do
    %__MODULE__{
      source: source,
      promoted_to: promoted_to
    }
  end
end
