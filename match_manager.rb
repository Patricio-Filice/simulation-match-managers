require_relative 'context_constants'
require_relative 'match_stand'

class MatchManager
  attr_accessor :region_name,
                :number_of_matchs,
                :max_simultaneous_matchs,
                :matchs_stands,
                :first_delegated_matcher_manager,
                :second_delegated_match_manager,
                :time_next_ending_match,
                :next_ending_match

  def initialize(region_name, max_simultaneous_matchs)
    self.region_name = region_name
    self.number_of_matchs = 0
    self.max_simultaneous_matchs = max_simultaneous_matchs
    self.time_next_ending_match = ContextConstants::HIGH_VALUE
    self.matchs_stands = Array.new(max_simultaneous_matchs) { MatchStand.new }
  end

  def create_match(simulation_context)
    increment_redirections_by_one = proc { |delegated_simulation_context| delegated_simulation_context.groups_redirected_one_time += 1 }
    increment_redirections_by_two = proc { |delegated_simulation_context| delegated_simulation_context.groups_redirected_two_times += 1 }
    reject_group = proc { |delegated_simulation_context| increment_redirections_by_one.call(delegated_simulation_context); increment_redirections_by_two.call(delegated_simulation_context); delegated_simulation_context.groups_could_not_play += 1 }

    if self.can_create_match
      self.new_match(simulation_context)
    elsif self.first_delegated_matcher_manager.can_create_match
      increment_redirections_by_one.call(simulation_context)
      self.first_delegated_matcher_manager.new_match(simulation_context)
    elsif self.second_delegated_match_manager.can_create_match
      increment_redirections_by_two.call(simulation_context)
      self.second_delegated_match_manager.new_match(simulation_context)
    else
      reject_group.call(simulation_context)
    end
  end

  def assign_alternative_matchers(first_delegated_matcher_manager, second_delegated_match_manager)
    self.first_delegated_matcher_manager = first_delegated_matcher_manager
    self.second_delegated_match_manager = second_delegated_match_manager
  end

  def can_create_match
    self.number_of_matchs + 1 <= self.max_simultaneous_matchs
  end

  def new_match(simulation_context)
    simulation_context.groups_could_play += 1
    self.number_of_matchs += 1
    match_stand = self.matchs_stands.detect { |match_stand| match_stand.match_ending_time == ContextConstants::HIGH_VALUE }
    match_duration = simulation_context.match_duration
    match_stand.match_ending_time = simulation_context.time + match_duration
    match_stand.calculate_laziness(simulation_context.time)
    self.calculate_next_ending_match
  end

  def end_match(simulation_context)
    match_stand = self.matchs_stands.detect { |match_stand| match_stand == self.next_ending_match }
    simulation_context.time = match_stand.match_ending_time
    self.number_of_matchs -= 1
    match_stand.last_time_disoccupied = simulation_context.time
    match_stand.match_ending_time = ContextConstants::HIGH_VALUE
    self.calculate_next_ending_match
  end

  def calculate_next_ending_match
    self.next_ending_match = self.matchs_stands.sort_by { |match_stand| match_stand.match_ending_time }[0]
    self.time_next_ending_match = self.next_ending_match.match_ending_time
  end

  def status
    "Region: #{self.region_name}: - Number of Matchs: #{self.number_of_matchs} - Time Next Ending Match: #{self.time_next_ending_match}"
  end
end