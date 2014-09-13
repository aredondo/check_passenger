require File.expand_path('test_helper', File.dirname(__FILE__))

describe CheckPassenger::Parser do
  describe 'minimum data processing' do
    before do
      @sample_output = <<-HEREDOC
        ----------- General information -----------
        Max pool size : 40
        Processes     : 26
        Requests in top-level queue : 0

        ----------- Application groups -----------
      HEREDOC
    end

    it 'correctly handles process life' do
      begin
        parser = CheckPassenger::Parser.new(@sample_output)
      rescue Exception => e
        assert false, 'Exception %s raised with message: %s' % [e.class.to_s, e.to_s]
      end

      last_used = '23x 4d 5h 4s'
      assert_raises CheckPassenger::StatusOutputError do
        parser.send(:'is_process_alive?', last_used)
      end

      last_used = '4d 5h 4s'

      begin
        life_in_seconds = parser.send(:life_to_seconds, last_used)
      rescue Exception => e
        assert false, 'Exception %s raised with message: %s' % [e.class.to_s, e.to_s]
      end
      assert_equal 363_604, life_in_seconds

      refute parser.send(:'is_process_alive?', last_used)
    end

    it 'correctly parses max pool size' do
      parser = CheckPassenger::Parser.new(@sample_output)
      assert_equal 40, parser.max_pool_size

      sample_output = @sample_output.gsub('Max pool size : 40', 'Max pool size : b40')
      assert_raises CheckPassenger::StatusOutputError do
        parser = CheckPassenger::Parser.new(sample_output)
      end

      sample_output = @sample_output.gsub('Max pool size : 40', '')
      assert_raises CheckPassenger::StatusOutputError do
        parser = CheckPassenger::Parser.new(sample_output)
      end
    end
  end

  describe 'sample output 1' do
    before do
      output = File.read(File.expand_path('sample_output_1.txt', File.dirname(__FILE__)))
      @parser = CheckPassenger::Parser.new(output)
    end

    it 'finds the names of the applications' do
      refute_empty @parser.application_names
      assert_equal 4, @parser.application_names.size
      assert_includes @parser.application_names, '/home/application_3/Site'
    end

    it 'reports the maximum number of processes' do
      refute_nil @parser.max_pool_size
      assert_equal 40, @parser.max_pool_size
    end

    describe 'for all applications' do
      it 'reports all memory used' do
        refute @parser.memory.nil?
        assert @parser.memory > 0
      end

      it 'reports the total count of processes' do
        assert_equal 26, @parser.process_count
      end

      it 'reports the number of live processes' do
        assert_equal 9, @parser.live_process_count
      end
    end

    describe 'for a specific application' do
      it 'reports memory used' do
        assert_equal 65, @parser.memory('application_2')
      end

      it 'reports the process count' do
        assert_equal 12, @parser.process_count('application_1')
      end

      it 'reports the live process count' do
        assert_equal 3, @parser.live_process_count('application_1')
        assert_equal 4, @parser.live_process_count('application_4')
      end

      it 'raises exception if term matches multiple apps' do
        assert_raises ArgumentError do
          @parser.memory('application')
        end
      end
    end
  end

  describe 'sample output 2' do
    before do
      output = File.read(File.expand_path('sample_output_2.txt', File.dirname(__FILE__)))
      @parser = CheckPassenger::Parser.new(output)
    end

    it 'finds the names of the applications' do
      refute_empty @parser.application_names
      assert_equal 3, @parser.application_names.size
      assert_includes @parser.application_names, '/home/application_2/Site'
    end

    it 'reports the maximum number of processes' do
      refute_nil @parser.max_pool_size
      assert_equal 40, @parser.max_pool_size
    end

    describe 'for all applications' do
      it 'reports all memory used' do
        refute @parser.memory.nil?
        assert @parser.memory > 0
      end

      it 'reports the total count of processes' do
        assert_equal 22, @parser.process_count
    end

      it 'reports the number of live processes' do
        assert_equal 7, @parser.live_process_count
      end
    end

    describe 'for a specific application' do
      it 'reports memory used' do
        assert_equal 2935, @parser.memory('application_3')
      end

      it 'reports the process count' do
        assert_equal 4, @parser.process_count('application_2')
      end

      it 'reports the live process count' do
        assert_equal 4, @parser.live_process_count('application_1')
        assert_equal 0, @parser.live_process_count('application_2')
      end
    end
  end
end
