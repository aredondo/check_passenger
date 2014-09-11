module CheckPassenger
  class Parser
    UNIT_MULTIPLIERS = { 's' => 1, 'm' => 60, 'h' => 3_600, 'd' => 86_400 }

    attr_reader :max_pool_size

    def initialize(passenger_status_output)
      @passenger_status_output = passenger_status_output
      parse_passenger_output
    end

    def application_names
      @application_data.map { |app_data| app_data[:name] }
    end

    def live_process_count(app_name = nil)
      if app_name
        app_data = @application_data.find { |a| a if a[:name].include?(app_name) }
        app_data ? app_data[:live_process_count] : nil
      else
        @application_data.inject(0) { |sum, e| sum + e[:live_process_count] }
      end
    end

    def memory(app_name = nil)
      if app_name
        app_data = @application_data.find { |a| a if a[:name].include?(app_name) }
        app_data ? app_data[:memory] : nil
      else
        @application_data.inject(0) { |sum, e| sum + e[:memory] }
      end
    end

    def process_count(app_name = nil)
      if app_name
        app_data = @application_data.find { |a| a if a[:name].include?(app_name) }
        app_data ? app_data[:process_count] : nil
      else
        @process_count
      end
    end

    private

    def is_process_alive?(last_used)
      life_to_seconds(last_used) < LIVE_PROCESS_TTL_IN_SECONDS
    end

    def life_to_seconds(last_used)
      last_used.split(/\s+/).inject(0) do |sum, part|
        if part =~ /^(\d+)([a-z])$/
          unless UNIT_MULTIPLIERS.has_key?($2)
            raise StatusOutputError, 'Unknown time unit "%s" in "%s"' % [$2, last_used]
          end
          sum + $1.to_i * UNIT_MULTIPLIERS[$2]
        else
          sum
        end
      end
    end

    def parse_application_data(output)
      output.split("\n\n").map do |app_output|
        app_data = {}

        app_output =~ /App root: +([^\n]+)/
        raise StatusOutputError, 'Could not find app name' unless $1
        app_data[:name] = $1.strip

        app_data[:process_count] = app_output.scan(/PID *: *\d+/).size
        app_data[:memory] = app_output.scan(/Memory *: *(\d+)M/).inject(0.0) { |s, m| s + m[0].to_f }
        app_data[:live_process_count] = (
          app_output.scan(/Last used *: *([^\n]+)/).select { |m| is_process_alive?(m[0]) }
        ).size

        app_data
      end
    end

    def parse_passenger_output
      @passenger_status_output =~ /^(.*?)-+ +Application groups +-+[^\n]*\n(.*)$/m
      raise StatusOutputError, 'Did not find "Application groups" section' unless $1

      generic_data = $1
      application_data = $2

      generic_data =~ /Max pool size *: *(\d+)/
      raise StatusOutputError, 'Could not find max pool size' unless $1
      @max_pool_size = $1.to_i

      generic_data =~ /Processes *: *(\d+)/
      raise StatusOutputError, 'Could not find process count' unless $1
      @process_count = $1.to_i

      @application_data = parse_application_data(application_data)
    end
  end
end
