module CheckPassenger
  class PassengerStatus
    class << self
      attr_accessor :path

      def run
        `#{passenger_status_executable_path}`
      end

      private

      def passenger_status_executable_path
        command = if @path and File.exist?(@path)
          if File.directory?(@path)
            File.expand_path('passenger-status', @path)
          else
            @path
          end
        else
          `which passenger-status`.strip
        end

        fail Errno::ENOENT, 'Cannot find passenger-status' unless File.executable?(command)

        command
      end
    end
  end
end
