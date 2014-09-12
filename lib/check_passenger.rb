%w{
  parser
  passenger_status
  status_output_error
  version
}.each { |lib| require 'check_passenger/' + lib }

module CheckPassenger
  LIVE_PROCESS_TTL_IN_SECONDS = 300
end
