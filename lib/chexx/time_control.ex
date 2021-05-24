defprotocol Chexx.TimeControl do
  def start(tc, timestamp)
  def switch(tc, timestamp)
  def flag_fall?(tc, player, timestamp)
  def time_remaining(tc, player, timestamp, time_unit \\ :millisecond)
end
