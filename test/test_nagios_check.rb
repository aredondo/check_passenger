require File.expand_path('test_helper', File.dirname(__FILE__))

describe CheckPassenger::NagiosCheck do
  before do
    @obj = Class.new do
      extend CheckPassenger::NagiosCheck
    end
  end

  describe '#nagios_status' do
    it 'returns the correct status' do
      assert_equal :ok, @obj.send(:nagios_status, 2)
      assert_equal :ok, @obj.send(:nagios_status, 2, { warn: '3' })
      assert_equal :warn, @obj.send(:nagios_status, 6, { warn: '5' })
      assert_equal :warn, @obj.send(:nagios_status, -1, { warn: '5' })
      assert_equal :crit, @obj.send(:nagios_status, 6, { warn: '5', crit: '5' })
    end
  end

  describe '#number_outside_range?' do
    it 'processes simple numbers' do
      assert @obj.send(:'number_outside_range?', -1, '10')
      refute @obj.send(:'number_outside_range?', 0, '10')
      refute @obj.send(:'number_outside_range?', 10, '10')
      assert @obj.send(:'number_outside_range?', 11, '10')
    end

    it 'processes ranges with empty ends' do
      assert @obj.send(:'number_outside_range?', -1, '10:')
      assert @obj.send(:'number_outside_range?', 9, '10:')
      refute @obj.send(:'number_outside_range?', 10, '10:')
      refute @obj.send(:'number_outside_range?', 100, '10:')
    end

    it 'processes ranges to inifinity' do
      refute @obj.send(:'number_outside_range?', -1, '~:10')
      refute @obj.send(:'number_outside_range?', 10, '~:10')
      assert @obj.send(:'number_outside_range?', 11, '~:10')
      assert @obj.send(:'number_outside_range?', 100, '~:10')
    end

    it 'processes delimited ranges' do
      assert @obj.send(:'number_outside_range?', -1, '10:20')
      assert @obj.send(:'number_outside_range?', 9, '10:20')
      refute @obj.send(:'number_outside_range?', 10, '10:20')
      refute @obj.send(:'number_outside_range?', 15, '10:20')
      refute @obj.send(:'number_outside_range?', 20, '10:20')
      assert @obj.send(:'number_outside_range?', 21, '10:20')
      assert @obj.send(:'number_outside_range?', 100, '10:20')
    end

    it 'processes negative delimited ranges' do
      refute @obj.send(:'number_outside_range?', -1, '@10:20')
      refute @obj.send(:'number_outside_range?', 9, '@10:20')
      assert @obj.send(:'number_outside_range?', 10, '@10:20')
      assert @obj.send(:'number_outside_range?', 15, '@10:20')
      assert @obj.send(:'number_outside_range?', 20, '@10:20')
      refute @obj.send(:'number_outside_range?', 21, '@10:20')
      refute @obj.send(:'number_outside_range?', 100, '@10:20')
    end

    it 'raises an exception on unknown range' do
      assert_raises ArgumentError do
        @obj.send(:'number_outside_range?', 100, '&10:20')
      end

      assert_raises ArgumentError do
        @obj.send(:'number_outside_range?', 100, ':')
      end
    end
  end
end
