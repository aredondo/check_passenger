module CheckPassenger
  module NagiosCheck
    EXIT_CODES = {ok: 0, warn: 1, crit: 2}

    private

    def nagios_error(message)
      puts message
      exit 3
    end

    def nagios_format_output(data)
      data = [data] unless data.is_a?(Array)
      main_status = nil
      status_data = []
      perf_data = []

      data.each do |line|
        case line
        when String
          status_text = line
        when Hash
          status_text = line[:text]
          perf_data << format('%s=%d;%s;%s;%s;%s',
                              line[:counter], line[:value], line[:warn], line[:crit], line[:min], line[:max])
        else
          fail ArgumentError
        end

        if main_status.nil?
          main_status = status_text
        else
          status_data << status_text
        end
      end

      [main_status, status_data, perf_data]
    end

    def nagios_output(status, data)
      unless [:ok, :warn, :crit].include?(status)
        fail ArgumentError, "Invalid status provided: #{status}"
      end

      main_status, status_data, perf_data = nagios_format_output(data)

      if perf_data.is_a?(Array) and perf_data.any?
        puts format('%s|%s', main_status, perf_data.join(' '))
      else
        puts main_status
      end
      status_data.each { |status_datum| puts status_datum }

      exit EXIT_CODES[status]
    end

    def nagios_range_to_condition(nagios_range)
      case nagios_range
      when /^(-?\d+)$/
        ->(n) { !(0..$1.to_i).include?(n) }
      when /^(-?\d+):~?$/
        ->(n) { n < $1.to_i }
      when /^~?:(-?\d+)$/
        ->(n) { n > $1.to_i }
      when /^(-?\d+):(-?\d+)$/
        ->(n) { !($1.to_i..$2.to_i).include?(n) }
      when /^@(-?\d+):(-?\d+)$/
        ->(n) { ($1.to_i..$2.to_i).include?(n) }
      else
        fail ArgumentError, "Cannot process Nagios range: #{nagios_range}"
      end
    end

    def nagios_status(counter, options = {})
      status = :ok
      [:warn, :crit].each do |level|
        status = level if options[level] && number_outside_range?(counter, options[level])
      end
      status
    end

    def number_outside_range?(number, nagios_range)
      nagios_range_to_condition(nagios_range).call(number)
    end
  end
end
