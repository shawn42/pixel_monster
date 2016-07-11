require 'yaml'

class Scoreboard
  SCORES_FILE = "scores.yml"
  def initialize
    load_from_file
    @scores ||= {}
  end

  def load_from_file
    if File.exists? SCORES_FILE
      File.open(SCORES_FILE,'r') do |f|
        @scores = YAML.load(f.read)
      end
    end
  end

  def write_to_file
    File.open(SCORES_FILE,'w') do |f|
      f.puts YAML.dump(@scores)
    end
  end

  def completed_level(level:,  number:)
    new_time = level.last_ms_to_complete
    return unless new_time

    old_time = @scores[number] || 1.0/0
    if new_time < old_time
      @scores[number] = new_time
    end
    puts "completed level #{number} with #{level.last_ms_to_complete}"
    puts "SCORES:"
    puts @scores.inspect

    write_to_file
  end
end
