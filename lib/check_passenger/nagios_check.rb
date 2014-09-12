module CheckPassenger
  module NagiosCheck
    EXIT_CODES = { ok: 0, warn: 1, crit: 2 }
    private

    def nagios_output(status, data)
      raise ArgumentError, 'Invalid status' unless [:ok, :warn, :crit].include?(status)

      data = [data] unless data.is_a?(Array)

      data.each do |line|
        raise ArgumentError, 'No status text provided' unless line.has_key?(:text)

        if line[:counter] and line[:value]
          puts '%s|%s=%d;%s;%s;%s;%s' % [
            line[:text],
            line[:counter], line[:value],
            line[:warn], line[:crit],
            line[:min], line[:max]
          ]
        else
          puts line[:text]
        end
      end

      exit EXIT_CODES[status]
    end

    def nagios_range_to_condition(nagios_range)
      case nagios_range
      when /^(-?\d+)$/
        lambda { |n| !(0 .. $1.to_i).include?(n) }
      when /^(-?\d+):~?$/
        lambda { |n| n < $1.to_i }
      when /^~?:(-?\d+)$/
        lambda { |n| n > $1.to_i }
      when /^(-?\d+):(-?\d+)$/
        lambda { |n| !($1.to_i .. $2.to_i).include?(n) }
      when /^@(-?\d+):(-?\d+)$/
        lambda { |n| ($1.to_i .. $2.to_i).include?(n) }
      else
        raise ArgumentError, 'Cannot process Nagios range: %s' % nagios_range
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
