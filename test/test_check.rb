require File.expand_path('test_helper', File.dirname(__FILE__))

describe CheckPassenger::Check do
  describe '#passenger_status' do
    it 'returns a PassengerStatus class' do
      assert_equal 'CheckPassenger::PassengerStatus', CheckPassenger::Check.send(:passenger_status).name
      assert_equal 'CheckPassenger::PassengerStatus',
          CheckPassenger::Check.send(:passenger_status, File.dirname(__FILE__)).name
    end
  end

  def output_data_structure_test(output_data)
    assert_kind_of Array, output_data

    output_data.each do |datum|
      assert_kind_of Hash, datum
      assert datum.key?(:text)
      assert datum.key?(:counter)
      assert datum.key?(:value)
    end
  end

  describe 'sample output 1' do
    before do
      sample_path = File.expand_path('sample_output_1.txt', File.dirname(__FILE__))
      data = File.read(sample_path)
      @parsed_data = CheckPassenger::Parser.new(data)
    end

    describe '#process_count' do
      it 'reports global process count' do
        options = {parsed_data: @parsed_data}
        output_status, output_data = CheckPassenger::Check.process_count(options)

        assert_equal :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'process_count', output_data.first[:counter]
        assert_equal 26, output_data.first[:value]
      end

      it 'reports global memory' do
        options = {parsed_data: @parsed_data}
        output_status, output_data = CheckPassenger::Check.memory(options)

        assert :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'memory', output_data.first[:counter]
        assert_equal 5_266, output_data.first[:value]
      end

      it 'reports data for all applications' do
        options = {parsed_data: @parsed_data, include_all: true}
        [:process_count, :memory, :live_process_count].each do |counter|
          output_status, output_data = CheckPassenger::Check.send(counter, options)

          assert_equal :ok, output_status
          output_data_structure_test(output_data)

          assert_equal 5, output_data.size
        end
      end

      it 'reports global live process count' do
        options = {parsed_data: @parsed_data}
        output_status, output_data = CheckPassenger::Check.live_process_count(options)

        assert :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'live_process_count', output_data.first[:counter]
        assert_equal 9, output_data.first[:value]
      end

      it 'reports global request queue' do
        options = {parsed_data: @parsed_data}
        output_status, output_data = CheckPassenger::Check.request_count(options)

        assert :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'request_count', output_data.first[:counter]
        assert_equal 60, output_data.first[:value]
      end

      it 'reports top-level queue size' do
        options = {parsed_data: @parsed_data}
        output_status, output_data = CheckPassenger::Check.top_level_request_count(options)

        assert :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'top_level_request_count', output_data.first[:counter]
        assert_equal 10, output_data.first[:value]
      end

      it 'reports application process count' do
        options = {parsed_data: @parsed_data, app_name: 'application_1'}
        output_status, output_data = CheckPassenger::Check.process_count(options)

        assert_equal :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'process_count', output_data.first[:counter]
        assert_equal 12, output_data.first[:value]
      end

      it 'reports application memory' do
        options = {parsed_data: @parsed_data, app_name: 'application_2'}
        output_status, output_data = CheckPassenger::Check.memory(options)

        assert_equal :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'memory', output_data.first[:counter]
        assert_equal 65, output_data.first[:value]
      end

      it 'reports application live process count' do
        options = {parsed_data: @parsed_data, app_name: 'application_3'}
        output_status, output_data = CheckPassenger::Check.live_process_count(options)

        assert_equal :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'live_process_count', output_data.first[:counter]
        assert_equal 1, output_data.first[:value]
      end

      it 'reports application request queue count' do
        options = {parsed_data: @parsed_data, app_name: 'application_4'}
        output_status, output_data = CheckPassenger::Check.request_count(options)

        assert_equal :ok, output_status
        output_data_structure_test(output_data)

        assert_equal 'request_count', output_data.first[:counter]
        assert_equal 14, output_data.first[:value]
      end

      it 'sets a warn alert when value over threshold' do
        options = {parsed_data: @parsed_data, app_name: 'application_4', warn: '150', crit: '300'}
        output_status, _output_data = CheckPassenger::Check.memory(options)
        assert_equal :warn, output_status
      end

      it 'sets a crit alert when value over threshold' do
        options = {parsed_data: @parsed_data, app_name: 'application_4', warn: '75', crit: '150'}
        output_status, _output_data = CheckPassenger::Check.memory(options)
        assert_equal :crit, output_status
      end
    end
  end

  describe 'sample output 3' do
    before do
      sample_path = File.expand_path('sample_output_3.txt', File.dirname(__FILE__))
      data = File.read(sample_path)
      @parsed_data = CheckPassenger::Parser.new(data)
    end

    it 'correctly uses singular/plural when reporting counts' do
      options = {parsed_data: @parsed_data}
      _output_status, output_data = CheckPassenger::Check.process_count(options)
      assert output_data.first[:text] =~ /\b6 processes\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.live_process_count(options)
      assert output_data.first[:text] =~ /\b1 live process\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.request_count(options)
      assert output_data.first[:text] =~ /\b79 requests\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.top_level_request_count(options)
      assert output_data.first[:text] =~ /\b13 top-level requests\b/, output_data.first[:text]

      options = {parsed_data: @parsed_data, app_name: 'application_1'}
      _output_status, output_data = CheckPassenger::Check.process_count(options)
      assert output_data.first[:text] =~ /\b1 process\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.live_process_count(options)
      assert output_data.first[:text] =~ /\b1 live process\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.request_count(options)
      assert output_data.first[:text] =~ /\b1 request\b/, output_data.first[:text]

      options = {parsed_data: @parsed_data, app_name: 'application_2'}
      _output_status, output_data = CheckPassenger::Check.process_count(options)
      assert output_data.first[:text] =~ /\b1 process\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.live_process_count(options)
      assert output_data.first[:text] =~ /\b0 live processes\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.request_count(options)
      assert output_data.first[:text] =~ /\b32 requests\b/, output_data.first[:text]

      options = {parsed_data: @parsed_data, app_name: 'application_3'}
      _output_status, output_data = CheckPassenger::Check.process_count(options)
      assert output_data.first[:text] =~ /\b4 processes\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.live_process_count(options)
      assert output_data.first[:text] =~ /\b0 live processes\b/, output_data.first[:text]
      _output_status, output_data = CheckPassenger::Check.request_count(options)
      assert output_data.first[:text] =~ /\b33 requests\b/, output_data.first[:text]
    end

    it 'raises an alert if the application is not running' do
      options = {parsed_data: @parsed_data, app_name: 'application_4'}
      output_status, output_data = CheckPassenger::Check.process_count(options)
      assert_equal :crit, output_status, output_data.inspect
    end
  end
end
