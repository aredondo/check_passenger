require 'tmpdir'

module CheckPassenger
  class Check
    class << self
      include CheckPassenger::NagiosCheck

      attr_reader :parsed_data

      COUNTER_LABELS = {
        live_process_count: '%d live processes',
        memory: '%dMB memory used',
        process_count: '%d processes'
      }

      def check_counter(counter_name, options = {})
        load_parsed_data(options)
        output_data = []

        counter = parsed_data.send(counter_name.to_sym, options[:app_name])
        output_status = nagios_status(counter, options)

        data = {
          text: 'Passenger %s %s - %s' %
                [
                  options[:app_name] || parsed_data.passenger_version,
                  output_status.to_s.upcase,
                  COUNTER_LABELS[counter_name.to_sym] % counter
                ],
          counter: counter_name.to_s, value: counter,
          warn: options[:warn], crit: options[:crit],
          min: 0, max: nil
        }
        if !options[:app_name] and [:process_count, :live_process_count].include?(counter_name.to_sym)
          data[:max] = parsed_data.max_pool_size
        end
        output_data << data

        if !options[:app_name] and options[:include_all]
          parsed_data.application_names.each do |app_name|
            counter = parsed_data.send(counter_name.to_sym, app_name)
            output_data << {
              text: '%s %s' % [app_name, COUNTER_LABELS[counter_name.to_sym] % counter],
              counter: app_name, value: counter
            }
          end
        end

        return [output_status, output_data]
      end

      def method_missing(method, *args)
        if COUNTER_LABELS.keys.include?(method)
          check_counter(method, *args)
        else
          super
        end
      end

      def respond_to?(method)
        return true if COUNTER_LABELS.keys.include?(method)
        super
      end

      private

      def load_parsed_data(options)
        @parsed_data = options[:parsed_data]

        if @parsed_data.nil? and options[:cache]
          cache_file_path = File.expand_path('check_passenger_cache.dump', Dir.tmpdir)

          if File.exist?(cache_file_path) and (Time.now - File.mtime(cache_file_path) < CACHE_TTL)
            File.open(cache_file_path, 'rb') { |file| @parsed_data = Marshal.load(file.read) }
          end
        end

        if @parsed_data.nil?
          @parsed_data = Parser.new(passenger_status(options[:passenger_status_path]).run)

          if options[:cache]
            File.open(cache_file_path, 'wb') { |file| file.write Marshal.dump(@parsed_data) }
          end
        end

        @parsed_data
      end

      def passenger_status(passenger_status_path = nil)
        @passenger_status ||= PassengerStatus
        @passenger_status.path = passenger_status_path
        @passenger_status
      end
    end
  end
end
