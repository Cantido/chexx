defmodule Chexx.Ply do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.

  A Ply is usually built from a single `Chexx.Touch`, but some moves require multiple touches,
  like castling.
  """

  alias Chexx.Touch
  alias Chexx.Square
  alias Chexx.Pieces.{
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn
  }

  @type parsed_notation() :: map()
  @type capture_type :: :allowed | :required | :forbidden
  @type t() :: %__MODULE__{
    touches: [Chexx.Touch.t()],
    capture: capture_type(),
    captures: Chexx.Square.t(),
    captured_piece_type: Chexx.Piece.piece() | nil,
    traverses: [Chexx.Square.t()],
    match_history_fn: ([String.t()] -> boolean())
  }

  @enforce_keys [
    :touches
  ]
  defstruct [
    touches: nil,
    capture: nil,
    captures: nil,
    captured_piece_type: nil,
    traverses: [],
    match_history_fn: &__MODULE__.default_match_history_fn/1
  ]

  @spec new(%{
    required(:touches) => [Chexx.Touch.t()],
    optional(:capture) => capture_type(),
    optional(:captures) => Chexx.Square.t(),
    optional(:captured_piece_type) => Chexx.Piece.piece(),
    optional(:traverses) => [Chexx.Square.t()],
    optional(:match_history_fn) => ([String.t()] -> boolean())
  }) :: t()
  def new(map) when is_map(map) do
    params = Map.take(map, [
      :touches,
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
      touches: [Touch.new(source, destination, piece)],
      capture: capture,
      captures: destination,
      traverses: traverses,
    }
  end

  @spec any_promotions?(t()) :: boolean()
  def any_promotions?(move) do
    Enum.any?(move.touches, fn movement ->
      movement.__struct__ == Chexx.Promotion
    end)
  end

  @spec possible_moves(parsed_notation(), Chexx.Color.t()) :: [t()]
  def possible_moves(notation, player) do
    case notation.move_type do
      :kingside_castle -> King.kingside_castle(player)
      :queenside_castle -> King.queenside_castle(player)
      :regular ->
        case notation.piece_type do
          :pawn -> Pawn.possible_pawn_sources(%Pawn{color: player}, notation.destination)
          :king -> King.possible_king_sources(%King{color: player}, notation.destination)
          :queen -> Queen.possible_queen_sources(%Queen{color: player}, notation.destination)
          :rook -> Rook.possible_rook_sources(%Rook{color: player}, notation.destination)
          :bishop -> Bishop.possible_bishop_sources(%Bishop{color: player}, notation.destination)
          :knight -> Knight.possible_knight_sources(%Knight{color: player}, notation.destination)
        end
    end
  end
end
