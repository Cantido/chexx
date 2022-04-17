defmodule Chexx.MoveNotation do
  defstruct [
    :move_type,
    :piece_type,
    :source_file,
    :source_rank,
    :destination,
    :capture,
    :check_status,
    :promoted_to,
    :notation_source
  ]
end
