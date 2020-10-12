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
    self.time = 0
    self.end_time = 50000
    self.groups_could_play = 0
    self.groups_could_not_play = 0
    self.groups_redirected_one_time = 0
    self.groups_redirected_two_times = 0
    self.time_next_match = 0
    self.asia_match_manager = MatchManager.new('Asia', 300)
    self.north_america_match_manager = MatchManager.new('North America', 400)
    self.europe_match_manager = MatchManager.new('Europe', 100)
    self.file_context_name = "execution_context_#{Time.now.strftime("%d_%m_%Y")}.txt"
    self.file_results_name = "execution_results_#{Time.now.strftime("%d_%m_%Y")}.txt"
  end

  def run
    File.write(self.file_context_name, "")
    self.asia_match_manager.assign_alternative_matchers(self.europe_match_manager, self.north_america_match_manager)
    self.north_america_match_manager.assign_alternative_matchers(self.europe_match_manager, self.asia_match_manager)
    self.europe_match_manager.assign_alternative_matchers(self.asia_match_manager, self.north_america_match_manager)

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
      File.write(self.file_context_name, actual_context, mode: "a")
    end

    total_laziness_asia = self.asia_match_manager.total_laziness
    total_laziness_north_america = self.north_america_match_manager.total_laziness
    total_laziness_europe = self.europe_match_manager.total_laziness
    total_groups = self.groups_could_play + self.groups_could_not_play
    results = "
                Percentage Laziness Asia: #{total_laziness_asia * 100 / self.time}
                Percentage Laziness North America: #{total_laziness_north_america * 100 / self.time}
                Percentage Laziness Europe: #{total_laziness_europe * 100 / self.time}
                Groups Could Play: #{self.groups_could_play}
                Groups Couldn't Play: #{self.groups_could_not_play}
                Percentage Groups Could Play: #{self.groups_could_play * 100 / total_groups}
                Percentage Groups Couldn't Play: #{self.groups_could_play * 100 / total_groups}
                Percentage Groups Were Redirected One Time: #{self.groups_redirected_one_time * 100 / total_groups}
                Percentage Groups Were Redirected Two Times: #{self.groups_redirected_two_times * 100 / total_groups}"
    File.write(self.file_results_name, results)
  end

  def arrival_interval
    numerator = (4.19859 * ((0.00591+rand) ** 0.5301))
    divider = ((1 + (3.88977 * ((0.00591+rand) ** 1.5301))) ** 1.70544)
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
end


simulation_context = SimulationContext.new

simulation_context.run