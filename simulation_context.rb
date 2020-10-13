require_relative 'match_manager'

class SimulationContext
  attr_accessor :time,
                :end_time,
                :groups_could_play,
                :groups_could_not_play,
                :groups_redirected_one_time,
                :groups_redirected_two_times,
                :time_next_match,
                :asia_match_manager,
                :north_america_match_manager,
                :europe_match_manager,
                :file_context_name,
                :file_results_name

  def initialize
  end

  def run(end_time, asia_max_simultaneous_matchs, north_america_max_simultaneous_matchs, europe_max_simultaneous_matchs)
    self.asia_match_manager = MatchManager.new('Asia', asia_max_simultaneous_matchs, self.europe_match_manager, self.north_america_match_manager)
    self.north_america_match_manager = MatchManager.new('North America', north_america_max_simultaneous_matchs, self.europe_match_manager, self.asia_match_manager)
    self.europe_match_manager = MatchManager.new('Europe', europe_max_simultaneous_matchs, self.asia_match_manager, self.north_america_match_manager)
    self.time = 0
    self.end_time = end_time
    self.groups_could_play = 0
    self.groups_could_not_play = 0
    self.groups_redirected_one_time = 0
    self.groups_redirected_two_times = 0
    self.time_next_match = 0
    self.file_context_name = "execution_context_#{Time.now.strftime("%d_%m_%Y")}"
    self.file_results_name = "execution_results_#{Time.now.strftime("%d_%m_%Y")}"

    File.write("#{self.file_context_name}.txt", "")



    match_managers = [self.asia_match_manager, self.north_america_match_manager, self.europe_match_manager]

    while self.time < self.end_time
      times_next_ending_match = match_managers.map {|match_manager| match_manager.time_next_ending_match }

      if times_next_ending_match.all? { |time_next_ending_match| time_next_ending_match >= self.time_next_match }
        self.create_match
      else
        lowest_time_next_ending_match = times_next_ending_match.sort[0]
        match_manger_with_ending_match = match_managers.detect { |match_manager| match_manager.time_next_ending_match == lowest_time_next_ending_match}
        match_manger_with_ending_match.end_match(self)
      end
      actual_context = " | Time: #{self.time} | Groups Could Play: #{self.groups_could_play} | Groups Couldn't Play: #{self.groups_could_not_play} | #{match_managers.reduce("") { |status, match_manager| match_manager.status + " | " + status  }}\n"
      puts actual_context
      File.write("#{self.file_context_name}.txt", actual_context, mode: "a")
    end

    match_managers.each { |match_manager| match_manager.adjust_match_laziness(self) }
    total_laziness_asia = self.asia_match_manager.total_laziness
    total_laziness_north_america = self.north_america_match_manager.total_laziness
    total_laziness_europe = self.europe_match_manager.total_laziness
    total_groups = self.groups_could_play + self.groups_could_not_play
    match_stands_laziness = match_managers.reduce("") { |laziness, match_manager| "#{laziness}#{match_manager.match_stands_laziness}\n"  }
    results = "Simulation Results - Asia Match Stands ##{asia_max_simultaneous_matchs} - North America Match Stands ##{north_america_max_simultaneous_matchs} - Europe Match Stands ##{europe_max_simultaneous_matchs}:
                Percentage Laziness Asia: #{total_laziness_asia * 100.0 / self.time}%
                Percentage Laziness North America: #{total_laziness_north_america * 100 / self.time}%
                Percentage Laziness Europe: #{total_laziness_europe * 100.0 / self.time}%
                Groups Could Play: #{self.groups_could_play}
                Groups Couldn't Play: #{self.groups_could_not_play}
                Percentage Groups Could Play: #{self.groups_could_play * 100.0 / total_groups}%
                Percentage Groups Couldn't Play: #{self.groups_could_not_play * 100.0 / total_groups}%
                Percentage Groups Were Redirected One Time: #{self.groups_redirected_one_time * 100.0 / total_groups}%
                Percentage Groups Were Redirected Two Times: #{self.groups_redirected_two_times * 100.0 / total_groups}%\n" + match_stands_laziness
    File.write("#{self.file_results_name}.txt", results)
  end

  def arrival_interval
    numerator = 4.19859 * ((0.00591+rand) ** 0.5301)
    divider = (1 + (3.88977 * ((0.00591+rand) ** 1.5301))) ** 1.70544
    numerator / divider
  end

  def match_duration
    (10 + rand * 5) * 60
  end

  def create_match
    self.time = self.time_next_match
    next_arrival = self.arrival_interval
    self.time_next_match += next_arrival

    region_probability = rand

    if region_probability <= 0.5
      self.north_america_match_manager.create_match(self)
    elsif region_probability <= 0.7
      self.europe_match_manager.create_match(self)
    else
      self.asia_match_manager.create_match(self)
    end
  end

  def run_with_sensibility_tweak()
    file_control_variables = File.open("control_variables.txt")
    control_variables = file_control_variables.readlines.map(&:chomp).map { |value| value.scan(/[1-9][0-9]*/)
                                                                                         .first
                                                                                         .to_i}
    file_control_variables.close

    asia_max_simultaneous_matchs = control_variables[0]
    north_america_max_simultaneous_matchs = control_variables[1]
    europe_max_simultaneous_matchs = control_variables[2]
    end_time = control_variables[3]
    percentage = control_variables[4] / 100.0

    self.run(end_time, (asia_max_simultaneous_matchs / percentage).round, (north_america_max_simultaneous_matchs / percentage).round, (europe_max_simultaneous_matchs / percentage).round)
    File.rename("#{self.file_context_name}.txt", "#{self.file_context_name}_upper_tweaked.txt")
    File.rename("#{self.file_results_name}.txt", "#{self.file_results_name}_upper_tweaked.txt")

    self.run(end_time, (asia_max_simultaneous_matchs * percentage).round, (north_america_max_simultaneous_matchs * percentage).round, (europe_max_simultaneous_matchs * percentage).round)
    File.rename("#{self.file_context_name}.txt", "#{self.file_context_name}_under_tweaked.txt")
    File.rename("#{self.file_results_name}.txt", "#{self.file_results_name}_under_tweaked.txt")

    self.run(end_time, asia_max_simultaneous_matchs, north_america_max_simultaneous_matchs, europe_max_simultaneous_matchs)
  end
end


simulation_context = SimulationContext.new
simulation_context.run_with_sensibility_tweak
