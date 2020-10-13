require_relative 'context_constants'

class MatchStand
  attr_accessor :match_ending_time, :last_time_disoccupied, :laziness_time

  def initialize
    self.match_ending_time = ContextConstants::HIGH_VALUE
    self.last_time_disoccupied = 0
    self.laziness_time = 0
  end

  def calculate_laziness(actual_time)
    self.laziness_time += actual_time - self.last_time_disoccupied
  end
end