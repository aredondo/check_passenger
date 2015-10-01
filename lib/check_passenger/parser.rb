module CheckPassenger
  class Parser
    UNIT_MULTIPLIERS = {'s' => 1, 'm' => 60, 'h' => 3_600, 'd' => 86_400}

    attr_reader :max_pool_size, :passenger_status_output, :passenger_version

    def initialize(passenger_status_output)
      @passenger_status_output = passenger_status_output
      parse_passenger_status_output
    end

    def application_names
      @application_data.map { |app_data| app_data[:name] }
    end

    def live_process_count(app_name = nil)
      if app_name
        app_data = application_data(app_name)
        app_data[:live_process_count]
      else
        @application_data.reduce(0) { |sum, e| sum + e[:live_process_count] }
      end
    end

    def memory(app_name = nil)
      if app_name
        app_data = application_data(app_name)
        app_data[:memory]
      else
        @application_data.reduce(0) { |sum, e| sum + e[:memory] }
      end
    end

    def process_count(app_name = nil)
      if app_name
        app_data = application_data(app_name)
        app_data[:process_count]
      else
        @process_count
      end
    end

    def request_count(app_name = nil)
      if app_name
        app_data = application_data(app_name)
        app_data[:request_count]
      else
        @application_data.reduce(@top_level_request_count) { |sum, e| sum + e[:request_count] }
      end
    end

    def top_level_request_count(_ = nil)
      @top_level_request_count
    end

    private

    def application_data(app_name)
      if app_name
        data = @application_data.select { |d| d[:name].include?(app_name) }
        if data.size == 0
          fail NoApplicationError.new('Application is not running', app_name)
        elsif data.size > 1
          fail MultipleApplicationsError.new("More than one running application match '#{app_name}'", app_name)
        else
          return data.first
        end
      else
        return @application_data
      end
    end

    def is_process_alive?(last_used)
      life_to_seconds(last_used) < LIVE_PROCESS_TTL_IN_SECONDS
    end

    def life_to_seconds(last_used)
      last_used.split(/\s+/).reduce(0) do |sum, part|
        if part =~ /^(\d+)([a-z])$/
          unless UNIT_MULTIPLIERS.key?($2)
            fail StatusOutputError.new("Unknown time unit '#{$2}' in '#{last_used}'", passenger_status_output)
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
        fail StatusOutputError.new('Could not find app name', passenger_status_output) unless $1
        app_data[:name] = $1.strip

        app_output =~ /Requests in queue: *(\d+)/
        fail StatusOutputError.new('Could not find application queued requests', passenger_status_output) unless $1
        app_data[:request_count] = $1.strip.to_i

        app_data[:process_count] = app_output.scan(/PID *: *\d+/).size
        app_data[:memory] = app_output.scan(/Memory *: *(\d+)M/).reduce(0.0) { |s, m| s + m[0].to_f }
        app_data[:live_process_count] = (
          app_output.scan(/Last used *: *([^\n]+)/).select { |m| is_process_alive?(m[0]) }
        ).size

        app_data
      end
    end

    def parse_passenger_status_output
      passenger_status_output =~ /^(.*?)-+ +Application groups +-+[^\n]*\n(.*)$/m
      fail StatusOutputError.new('Did not find "Application groups" section', passenger_status_output) unless $1

      generic_data = $1
      application_data = $2

      generic_data =~ /Version *: *([.\d]+)/
      fail StatusOutputError.new('Could not find Passenger version', passenger_status_output) unless $1
      @passenger_version = $1

      generic_data =~ /Max pool size *: *(\d+)/
      fail StatusOutputError.new('Could not find max pool size', passenger_status_output) unless $1
      @max_pool_size = $1.to_i

      generic_data =~ /Processes *: *(\d+)/
      fail StatusOutputError.new('Could not find process count', passenger_status_output) unless $1
      @process_count = $1.to_i

      generic_data =~ /Requests in top-level queue *: *(\d+)/
      fail StatusOutputError.new('Could not find top-level queued requests', passenger_status_output) unless $1
      @top_level_request_count = $1.to_i

      @application_data = parse_application_data(application_data)
    end
  end
end
