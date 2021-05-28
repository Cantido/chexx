defprotocol Chexx.Piece do
  def type(piece)
  def color(piece)
  def to_symbol(piece)
  def moves_from(piece, square)
  def moves_to(piece, square)
end
