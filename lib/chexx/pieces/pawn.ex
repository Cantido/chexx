defmodule Chexx.Pieces.Pawn do
  @enforce_keys [:color]
  defstruct [:color]

  alias Chexx.Piece
  alias Chexx.Pieces.{
    Queen,
    Rook,
    Bishop,
    Knight
  }
  alias Chexx.Ply
  alias Chexx.Touches.Promotion
  alias Chexx.Square
  alias Chexx.Touches.Travel

  def possible_pawn_moves(%__MODULE__{color: player}, source) do
    piece = %__MODULE__{color: player}
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

    forward_moves = [Ply.single_touch(piece, source, Square.move_direction(source, advance_direction, 1), capture: :forbidden)]

    forward_moves =
      if source.rank == start_rank do
        move = Ply.single_touch(piece, source, Square.move_direction(source, advance_direction, 2), capture: :forbidden)
        [move | forward_moves]
      else
        forward_moves
      end

    capture_right_dest = source |> Square.move_direction(advance_direction) |> Square.right()
    capture_left_dest = source |> Square.move_direction(advance_direction) |> Square.left()

    capture_moves = [
      Ply.single_touch(piece, source, capture_right_dest, capture: :required, captures: capture_right_dest),
      Ply.single_touch(piece, source, capture_left_dest, capture: :required, captures: capture_left_dest)
    ]

    en_passant_moves = [
      Ply.single_touch(piece, source, capture_right_dest, capture: :required, captures: Square.right(source), capture_piece_type: :pawn),
      Ply.single_touch(piece, source, capture_left_dest, capture: :required, captures: Square.left(source), capture_piece_type: :pawn)
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

  def possible_pawn_sources(%__MODULE__{color: player}, destination) do
    moves =
      possible_pawn_captures(player, destination) ++ possible_pawn_advances(player, destination)

    Enum.flat_map(moves, fn move ->
      upgrade_move_to_pawn_promotions(move)
    end)
  end

  defp upgrade_move_to_pawn_promotions(move) do
    if Enum.count(move.touches) == 1 do
      [touch] = move.touches
      if Piece.type(touch.piece) == :pawn do
        can_promote? =
          case {touch.piece.color, touch.destination.rank} do
            {:white, 8} -> true
            {:white, _} -> false
            {:black, 1} -> true
            {:black, _} -> false
          end

        if can_promote? do
          promotions =
            [
              %Queen{color: Piece.color(touch.piece)},
              %Rook{color: Piece.color(touch.piece)},
              %Bishop{color: Piece.color(touch.piece)},
              %Knight{color: Piece.color(touch.piece)}
            ]
            |> Enum.map(fn piece ->
              %Promotion{
                source: touch.destination,
                promoted_to: piece
              }
            end)

          Enum.map(promotions, fn promotion ->
            %{move | touches: move.touches ++ [promotion]}
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

      captured_pawn_last_moved_to_this_square? =
        if Enum.empty?(history) do
          false
        else
          last_move_destination =
            Enum.at(history, 0)
            |> Map.get(:touches)
            |> Enum.at(0)
            |> Map.get(:destination)

          last_move_destination == ep_captured_square
        end

      # captured pawn's previous move was two squares
      captured_pawn_didnt_move_previously? =
        Enum.take_every(history, 2)
        |> Enum.all?(fn move ->
          forbidden_square =
            case player do
              :white -> Square.down(ep_captured_square)
              :black -> Square.up(ep_captured_square)
            end
          not Square.equals?(Enum.at(move.touches, 0).destination, forbidden_square)
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
        %Ply{
          player: player,
          touches: [%Travel{source: source, destination: destination, piece: %__MODULE__{color: player}}],
          capture: :required,
          captures: ep_captured_square,
          captured_piece_type: :pawn,
          match_history_fn: required_history_fn
        }
      end)

    regular_moves =
      sources
      |> Enum.map(fn source ->
        %Ply{
          player: player,
          touches: [%Travel{source: source, destination: destination, piece: %__MODULE__{color: player}}],
          capture: :required,
          captures: destination
        }
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
      Ply.single_touch(%__MODULE__{color: player}, move_one_source, destination, capture: :forbidden)

    move_two_source =
      case player do
        :white -> Square.down(destination, 2)
        :black -> Square.up(destination, 2)
      end

    move_two =
      Ply.single_touch(%__MODULE__{color: player}, move_two_source, destination, capture: :forbidden)

    cond do
      can_move_two? -> [move_one, move_two]
      true -> [move_one]
    end
  end

  defimpl Chexx.Piece do
    def to_string(%{color: :white}), do: "♙"
    def to_string(%{color: :black}), do: "♟︎"
    def moves_from(piece, square), do: Chexx.Pieces.Pawn.possible_pawn_moves(piece, square)
    def moves_to(piece, square), do: Chexx.Pieces.Pawn.possible_pawn_sources(piece, square)
    def type(_piece), do: :pawn
    def color(%{color: color}), do: color
  end
end
