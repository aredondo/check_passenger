module CheckPassenger
  class Check
    class << self
      include CheckPassenger::NagiosCheck

      COUNTER_LABELS = {
        live_process_count: '%d live processes',
        memory: '%dMB memory used',
        process_count: '%d processes'
      }

      def method_missing(method, *args)
        if COUNTER_LABELS.keys.include?(method)
          check_counter(method, *args)
        else
          super
        end
      end

      def check_counter(counter_name, options = {})
        status_data = load_parsed_data(options)
        output_data = []

        counter = status_data.send(counter_name.to_sym, options[:app])
        output_status = nagios_status(counter, options)

        data = {
          text: '%s %s - %s' %
                [
                  options[:app] || 'Passenger',
                  output_status.to_s.upcase,
                  COUNTER_LABELS[counter_name.to_sym] % counter
                ],
          counter: counter_name.to_s, value: counter,
          warn: options[:warn], crit: options[:crit],
          min: 0, max: nil
        }
        if [:process_count, :live_process_count].include?(counter_name.to_sym)
          data[:max] = status_data.max_pool_size
        end
        output_data << data

        if !options[:app] and options[:include_all]
          status_data.application_names.each do |app_name|
            counter = status_data.send(counter_name.to_sym, app_name)
            output_data << {
              text: '%s %s' % [app_name, COUNTER_LABELS[counter_name.to_sym] % counter],
              counter: counter_name.to_s, value: counter
            }
          end
        end

        return [output_status, output_data]
      end

      def respond_to?(method)
        return true if COUNTER_LABELS.keys.include?(method)
        super
      end

      private

      def load_parsed_data(options)
        if options[:parsed_data]
          options[:parsed_data]
        else
          Parser.new(passenger_status(options[:passenger_status_path]).run)
        end
      end

      def passenger_status(passenger_status_path = nil)
        @passenger_status ||= PassengerStatus
        @passenger_status.path = passenger_status_path
        @passenger_status
      end
    end
  end
end
