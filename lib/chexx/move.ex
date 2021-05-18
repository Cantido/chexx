defmodule Chexx.Move do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.

  A Move is usually built from a single `Chexx.Touch`, but some moves require multiple touches,
  like castling.
  """

  alias Chexx.Touch
  alias Chexx.Square

  @type capture_type :: :allowed | :required | :forbidden
  @type t() :: %__MODULE__{
    movements: [Chexx.Touch.t()],
    capture: capture_type(),
    captures: Chexx.Square.t(),
    captured_piece_type: Chexx.Piece.piece() | nil,
    traverses: [Chexx.Square.t()],
    match_history_fn: ([String.t()] -> boolean())
  }

  @enforce_keys [
    :movements
  ]
  defstruct [
    movements: nil,
    capture: nil,
    captures: nil,
    captured_piece_type: nil,
    traverses: [],
    match_history_fn: &__MODULE__.default_match_history_fn/1
  ]

  @spec new(%{
    required(:movements) => [Chexx.Touch.t()],
    optional(:capture) => capture_type(),
    optional(:captures) => Chexx.Square.t(),
    optional(:captured_piece_type) => Chexx.Piece.piece(),
    optional(:traverses) => [Chexx.Square.t()],
    optional(:match_history_fn) => ([String.t()] -> boolean())
  }) :: t()
  def new(map) when is_map(map) do
    params = Map.take(map, [
      :movements,
      :capture,
      :captures,
      :captured_piece_type,
      :traverses,
      :match_history_fn
    ])
    struct(__MODULE__, params)
  end

  @spec default_match_history_fn([String.t()]) :: true
  def default_match_history_fn(_), do: true

  @spec single_touch(Chexx.Piece.t(), Chexx.Square.t(), Chexx.Square.t(), Keyword.t()) :: t()
  def single_touch(piece, source, destination, opts \\ []) do
    traverses =
      if Keyword.get(opts, :traverses, true) do
        Square.squares_between(source, destination)
      else
        []
      end

    capture = Keyword.get(opts, :capture, :allowed)

    %__MODULE__{
      movements: [Touch.new(source, destination, piece)],
      capture: capture,
      captures: destination,
      traverses: traverses,
    }
  end

  @spec any_promotions?(t()) :: boolean()
  def any_promotions?(move) do
    Enum.any?(move.movements, fn movement ->
      movement.__struct__ == Chexx.Promotion
    end)
  end
end
