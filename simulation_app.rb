require_relative 'simulation_context'

class SimulationApp
  def run
    file_control_variables = File.open("environment_variables.txt")
    environment_variables = file_control_variables.readlines.map(&:chomp).map { |value| value.scan(/[1-9][0-9]*/)
                                                                                        .first
                                                                                        .to_i}
    file_control_variables.close

    asia_max_simultaneous_matchs = environment_variables[0]
    europe_max_simultaneous_matchs = environment_variables[1]
    north_america_max_simultaneous_matchs = environment_variables[2]
    end_time = environment_variables[3]
    file_percentage = environment_variables[4] / 100.0
    percentage = (1 - file_percentage)
    half_percentage = (1 - file_percentage / 2)
    file_context_name = 'execution_context'
    file_results_name = 'execution_results'
    threads = []

    puts 'Starting Simulations'

    threads << create_simulation_thread('Upper Tweak', (asia_max_simultaneous_matchs / percentage).round, (north_america_max_simultaneous_matchs / percentage).round, (europe_max_simultaneous_matchs / percentage).round, end_time, file_context_name + '_upper_tweaked', file_results_name + '_upper_tweaked')
    threads << create_simulation_thread('Half Upper Tweak', (asia_max_simultaneous_matchs / half_percentage).round, (north_america_max_simultaneous_matchs / half_percentage).round, (europe_max_simultaneous_matchs / half_percentage).round, end_time, file_context_name + '_half_upper_tweaked', file_results_name + '_half_upper_tweaked')
    threads << create_simulation_thread('No Tweak', asia_max_simultaneous_matchs, north_america_max_simultaneous_matchs, europe_max_simultaneous_matchs, end_time, file_context_name, file_results_name)
    threads << create_simulation_thread('Half Under Tweak', (asia_max_simultaneous_matchs * half_percentage).round, (north_america_max_simultaneous_matchs * half_percentage).round, (europe_max_simultaneous_matchs * half_percentage).round, end_time, file_context_name + '_half_under_tweaked', file_results_name + '_half_under_tweaked')
    threads << create_simulation_thread('Under Tweak', (asia_max_simultaneous_matchs * percentage).round, (north_america_max_simultaneous_matchs * percentage).round, (europe_max_simultaneous_matchs * percentage).round, end_time, file_context_name + '_under_tweaked', file_results_name + '_under_tweaked')
    threads.each(&:join)

    puts 'Finished Simulations'
  end

  private def create_simulation_thread(simulation_name, asia_max_simultaneous_matchs, north_america_max_simultaneous_matchs, europe_max_simultaneous_matchs, end_time, file_context_name, file_results_name)
    Thread.new {
      puts "Starting #{simulation_name} Simulation"
      simulation_context = SimulationContext.new(asia_max_simultaneous_matchs, north_america_max_simultaneous_matchs, europe_max_simultaneous_matchs)
      simulation_context.run(end_time, file_context_name, file_results_name)
      puts "Finishing #{simulation_name} Simulation"
    }
  end
end

simulation_app = SimulationApp.new
simulation_app.run