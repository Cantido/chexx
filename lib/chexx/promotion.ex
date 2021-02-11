defmodule Chexx.Promotion do
  alias Chexx.Square
  alias Chexx.Piece

  @enforce_keys [
    :source,
    :promoted_to
  ]
  defstruct [
    :source,
    :promoted_to
  ]

  def new(%Square{} = source, %Piece{} = promoted_to) do
    %__MODULE__{
      source: source,
      promoted_to: promoted_to
    }
  end
end
