module CheckPassenger
  class StatusOutputError < RuntimeError
    attr_accessor :passenger_status_output

    def initialize(message, passenger_status_output = nil)
      @passenger_status_output = passenger_status_output
      super(message)
    end
  end
end
