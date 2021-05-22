defmodule Chexx.Ply do
  @moduledoc """
  Encapsulates a change in `Chexx.Piece`'s position on a `Chexx.Board`,
  along with certain requirements of the move.

  A Ply is usually built from a single `Chexx.Touch`, but some moves require multiple touches,
  like castling.
  """

  alias Chexx.Touch
  alias Chexx.Square
  alias Chexx.Piece
  alias Chexx.Promotion

  @type parsed_notation() :: map()
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

  @spec possible_moves(parsed_notation(), Chexx.Color.t()) :: [t()]
  def possible_moves(notation, player) do
    case notation.move_type do
      :kingside_castle -> kingside_castle(player)
      :queenside_castle -> queenside_castle(player)
      :regular ->
        case notation.piece_type do
          :pawn -> possible_pawn_sources(player, notation.destination)
          :king -> possible_king_sources(player, notation.destination)
          :queen -> possible_queen_sources(player, notation.destination)
          :rook -> possible_rook_sources(player, notation.destination)
          :bishop -> possible_bishop_sources(player, notation.destination)
          :knight -> possible_knight_sources(player, notation.destination)
        end
    end
  end

  def kingside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.movements, &Piece.equals?(&1.piece, by, :king))
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.movements, fn movement ->
            rook_start_rank =
              case by do
                :white -> 1
                :black -> 8
              end
            Piece.equals?(movement.piece, by, :rook) and Square.equals?(movement.source, 8, rook_start_rank)
          end)
        end)

      not king_moved_before? and not rook_moved_before?
    end


    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:g, 1)
        :black -> Square.new(:g, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:h, 1)
        :black -> Square.new(:h, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:f, 1)
        :black -> Square.new(:f, 8)
      end

    [new(%{
      movements: [
        Touch.new(king_start_pos, king_dest_pos, Piece.new(:king, by)),
        Touch.new(rook_start_pos, rook_dest_pos, Piece.new(:rook, by)),
      ],
      match_history_fn: match_history_fn
    })]
  end

  def queenside_castle(by) do
    match_history_fn = fn history ->
      king_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.movements, &Piece.equals?(&1.piece, by, :king))
        end)

      rook_moved_before? =
        Enum.any?(history, fn move ->
          Enum.any?(move.movements, fn movement ->
            rook_start_rank =
              case by do
                :white -> 1
                :black -> 8
              end
            Piece.equals?(movement.piece, by, :rook) and Square.equals?(movement.source, 1, rook_start_rank)
          end)
        end)

      not king_moved_before? and not rook_moved_before?
    end

    king_start_pos =
      case by do
        :white -> Square.new(:e, 1)
        :black -> Square.new(:e, 8)
      end

    king_dest_pos =
      case by do
        :white -> Square.new(:c, 1)
        :black -> Square.new(:c, 8)
      end

    rook_start_pos =
      case by do
        :white -> Square.new(:a, 1)
        :black -> Square.new(:a, 8)
      end

    rook_dest_pos =
      case by do
        :white -> Square.new(:d, 1)
        :black -> Square.new(:d, 8)
      end

    traversed_square =
      case by do
        :white -> Square.new(:b, 1)
        :black -> Square.new(:b, 8)
      end

    [new(%{
      movements: [
        Touch.new(king_start_pos, king_dest_pos, Piece.new(:king, by)),
        Touch.new(rook_start_pos, rook_dest_pos, Piece.new(:rook, by)),
      ],
      traverses: [traversed_square],
      match_history_fn: match_history_fn
    })]
  end

  def piece_equals?(piece, color, type) do
    not is_nil(piece) and piece.color == color and piece.type == type
  end

  def possible_pawn_moves(player, source) do
    piece = Piece.new(:pawn, player)
    advance_direction =
      case player do
        :white -> :up
        :black -> :down
      end
    start_rank =
      case player do
        :white -> 2
        :black -> 7
      end

    forward_moves = [single_touch(piece, source, Square.move_direction(source, advance_direction, 1), capture: :forbidden)]

    forward_moves =
      if source.rank == start_rank do
        move = single_touch(piece, source, Square.move_direction(source, advance_direction, 2), capture: :forbidden)
        [move | forward_moves]
      else
        forward_moves
      end

    capture_right_dest = source |> Square.move_direction(advance_direction) |> Square.right()
    capture_left_dest = source |> Square.move_direction(advance_direction) |> Square.left()

    capture_moves = [
      single_touch(piece, source, capture_right_dest, capture: :required, captures: capture_right_dest),
      single_touch(piece, source, capture_left_dest, capture: :required, captures: capture_left_dest)
    ]

    en_passant_moves = [
      single_touch(piece, source, capture_right_dest, capture: :required, captures: Square.right(source), capture_piece_type: :pawn),
      single_touch(piece, source, capture_left_dest, capture: :required, captures: Square.left(source), capture_piece_type: :pawn)
    ]

    en_passant_capture_rank =
      case player do
        :white -> 5
        :black -> 4
      end

    moves =
      if source.rank == en_passant_capture_rank do
        forward_moves ++ capture_moves ++ en_passant_moves
      else
        forward_moves ++ capture_moves
      end

    moves
    |> Enum.flat_map(fn move ->
      upgrade_move_to_pawn_promotions(move)
    end)
  end

  def possible_pawn_sources(player, destination) do
    moves =
      possible_pawn_captures(player, destination) ++ possible_pawn_advances(player, destination)

    Enum.flat_map(moves, fn move ->
      upgrade_move_to_pawn_promotions(move)
    end)
  end

  defp upgrade_move_to_pawn_promotions(move) do
    if Enum.count(move.movements) == 1 do
      [touch] = move.movements
      if touch.piece.type == :pawn do
        can_promote? =
          case {touch.piece.color, touch.destination.rank} do
            {:white, 8} -> true
            {:white, _} -> false
            {:black, 1} -> true
            {:black, _} -> false
          end

        if can_promote? do
          promotions =
            Enum.map([:queen, :rook, :bishop, :knight], fn piece_type ->
              %Promotion{
                source: touch.destination,
                promoted_to: Piece.new(piece_type, touch.piece.color)
              }
            end)

          Enum.map(promotions, fn promotion ->
            %{move | movements: move.movements ++ [promotion]}
          end)
        else
          [move]
        end
      else
        [move]
      end
    else
      [move]
    end
  end

  defp possible_pawn_captures(player, destination) do
    ep_captured_square =
      case player do
        :white -> Square.down(destination)
        :black -> Square.up(destination)
      end

    sources =
      [Square.left(ep_captured_square), Square.right(ep_captured_square)]

    # Most recent move was to current pos
    required_history_fn = fn history ->
      last_move_destination =
        Enum.at(history, 0)
        |> Map.get(:movements)
        |> Enum.at(0)
        |> Map.get(:destination)

      captured_pawn_last_moved_to_this_square? = last_move_destination == ep_captured_square

      # captured pawn's previous move was two squares
      captured_pawn_didnt_move_previously? =
        Enum.take_every(history, 2)
        |> Enum.all?(fn move ->
          forbidden_square =
            case player do
              :white -> Square.down(ep_captured_square)
              :black -> Square.up(ep_captured_square)
            end
          not Square.equals?(Enum.at(move.movements, 0).destination, forbidden_square)
        end)

      captured_pawn_last_moved_to_this_square? and
        captured_pawn_didnt_move_previously?
    end

    # capturing pawn must have advanced exactly three ranks
    capturing_pawn_advanced_exactly_three_ranks? =
      case player do
        :white -> ep_captured_square.rank == 5
        :black -> ep_captured_square.rank == 4
      end

    en_passant_moves =
      sources
      |> Enum.map(fn source ->
        new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, player))],
          capture: :required,
          captures: ep_captured_square,
          captured_piece_type: :pawn,
          match_history_fn: required_history_fn
        })
      end)

    regular_moves =
      sources
      |> Enum.map(fn source ->
        new(%{
          movements: [Touch.new(source, destination, Piece.new(:pawn, player))],
          capture: :required,
          captures: destination
        })
      end)

    if capturing_pawn_advanced_exactly_three_ranks? do
      en_passant_moves ++ regular_moves
    else
      regular_moves
    end
  end

  defp possible_pawn_advances(player, destination) do
    rank = destination.rank

    can_move_two? =
      case {player, rank} do
        {:white, 4} -> true
        {:white, _} -> false
        {:black, 5} -> true
        {:black, _} -> false
      end

    move_one_source =
      case player do
        :white -> Square.down(destination, 1)
        :black -> Square.up(destination, 1)
      end

    move_one =
      single_touch(Piece.new(:pawn, player), move_one_source, destination, capture: :forbidden)

    move_two_source =
      case player do
        :white -> Square.down(destination, 2)
        :black -> Square.up(destination, 2)
      end

    move_two =
      single_touch(Piece.new(:pawn, player), move_two_source, destination, capture: :forbidden)

    cond do
      can_move_two? -> [move_one, move_two]
      true -> [move_one]
    end
  end

  def possible_king_moves(player, source) do
    king_movements(source)
    |> Enum.map(fn destination ->
      single_touch(Piece.new(:king, player), source, destination)
    end)
  end

  def possible_king_sources(player, destination) do
    king_movements(destination)
    |> Enum.map(fn source ->
      single_touch(Piece.new(:king, player), source, destination)
    end)
  end

  defp king_movements(source) do
    for distance <- [1], direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  def possible_queen_moves(player, source) do
    queen_movements(source)
    |> Enum.map(fn destination ->
      single_touch(Piece.new(:queen, player), source, destination)
    end)
  end

  def possible_queen_sources(player, destination) do
    queen_movements(destination)
    |> Enum.map(fn source ->
      single_touch(Piece.new(:queen, player), source, destination)
    end)
  end

  defp queen_movements(source) do
    for distance <- 1..7, direction <- [:up, :up_right, :right, :down_right, :down, :down_left, :left, :up_left] do
      Square.move_direction(source, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  def possible_rook_moves(player, source) do
    rook_movements(source)
    |> Enum.map(fn destination ->
      single_touch(Piece.new(:rook, player), source, destination)
    end)
  end

  def possible_rook_sources(player, destination) do
    rook_movements(destination)
    |> Enum.map(fn source ->
      single_touch(Piece.new(:rook, player), source, destination)
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

  def possible_bishop_moves(player, source) do
    bishop_movements(source)
    |> Enum.map(fn destination ->
      single_touch(Piece.new(:bishop, player), source, destination)
    end)
  end

  def possible_bishop_sources(player, destination) do
    bishop_movements(destination)
    |> Enum.map(fn source ->
      single_touch(Piece.new(:bishop, player), source, destination)
    end)
  end

  defp bishop_movements(around) do
    for distance <- 1..7, direction <- [:up_right, :down_right, :down_left, :up_left] do
      Square.move_direction(around, direction, distance)
    end
    |> Enum.filter(fn square ->
      Square.within?(square, 1..8, 1..8)
    end)
  end

  def possible_knight_moves(player, source) do
    knight_movements(source)
    |> Enum.map(fn destination ->
      single_touch(Piece.new(:knight, player), source, destination, traverses: false)
    end)
  end

  def possible_knight_sources(player, destination) do
    knight_movements(destination)
    |> Enum.map(fn source ->
      single_touch(Piece.new(:knight, player), source, destination, traverses: false)
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
end
