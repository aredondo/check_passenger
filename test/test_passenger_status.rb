require File.expand_path('test_helper', File.dirname(__FILE__))

describe CheckPassenger::PassengerStatus do
  it 'raises an exception when cannot find the executable' do
    CheckPassenger::PassengerStatus.path = '/tmp'
    assert_raises Errno::ENOENT do
      CheckPassenger::PassengerStatus.run
    end

    CheckPassenger::PassengerStatus.path = '/tmp/passenger-status'
    assert_raises Errno::ENOENT do
      CheckPassenger::PassengerStatus.run
    end
  end

  it 'can find the executable in a directory' do
    CheckPassenger::PassengerStatus.path = File.dirname(__FILE__)
    begin
      CheckPassenger::PassengerStatus.run
    rescue Exception => e
      assert false, e.to_s
    end
  end

  it 'returns passenger-status output' do
    CheckPassenger::PassengerStatus.path = File.expand_path('passenger-status', File.dirname(__FILE__))
    output = CheckPassenger::PassengerStatus.run
    assert_includes output, 'Version'
    assert_includes output, 'App root'
    assert_includes output, 'Requests in queue'
  end
end
