require_relative 'test_helper'

class MeasureTest < Minitest::Test
  describe 'Measure' do
    include InMemoryAppenderHelper

    # Ensure that any log level can be measured and logged
    SemanticLogger::LEVELS.each do |level|
      measure_level = "measure_#{level}".to_sym

      describe "##{measure_level}" do
        it ':message' do
          assert_equal 'result', logger.send(measure_level, 'hello world') { 'result' }

          assert log = log_message
          assert_equal 'hello world', log.message
        end

        it ':level' do
          assert_equal 'result', logger.send(measure_level, 'hello world') { 'result' }

          assert log = log_message
          assert_equal level, log.level
        end

        it ':payload' do
          assert_equal 'result', logger.send(measure_level, 'hello world', payload: payload) { 'result' }

          assert log = log_message
          assert_equal payload, log.payload
        end

        describe ':min_duration' do
          it 'not log when faster' do
            assert_equal 'result', logger.send(measure_level, 'hello world', min_duration: 2000) { 'result' }
            refute log_message
          end

          it 'log when slower' do
            assert_equal 'result', logger.send(measure_level, 'hello world', min_duration: 200, payload: payload) { sleep 0.5; 'result' }

            assert log = log_message
            assert_equal 'hello world', log.message
          end
        end

        it ':exception' do
          assert_raises RuntimeError do
            logger.send(measure_level, 'hello world', payload: payload) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal level, log.level
        end

        it ':on_exception_level' do
          assert_raises RuntimeError do
            logger.measure(level, 'hello world', payload: payload, on_exception_level: :fatal) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal :fatal, log.level
        end

        describe 'log_exception' do
          it 'default' do
            assert_raises RuntimeError do
              logger.send(measure_level, 'hello world') { raise RuntimeError.new('Test') }
            end

            assert log = log_message
            refute log.exception
            assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          end

          it ':full' do
            assert_raises RuntimeError do
              logger.send(measure_level, 'hello world', log_exception: :full) { raise RuntimeError.new('Test') }
            end

            assert log = log_message
            assert log.exception.is_a?(RuntimeError)
            assert log.exception.backtrace
            assert_equal level, log.level
            assert_equal 'hello world', log.message
          end

          it ':partial' do
            assert_raises RuntimeError do
              logger.send(measure_level, 'hello world', log_exception: :partial) { raise RuntimeError.new('Test') }
            end

            assert log = log_message
            refute log.exception
            assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          end

          it ':none' do
            assert_raises RuntimeError do
              logger.send(measure_level, 'hello world', log_exception: :none) { raise RuntimeError.new('Test') }
            end

            assert log = log_message
            refute log.exception
            assert_equal 'hello world', log.message
          end
        end

        it ':metric' do
          metric_name = '/my/custom/metric'
          assert_equal 'result', logger.send(measure_level, 'hello world', metric: metric_name) { 'result' }

          assert log = log_message
          assert_equal metric_name, log.metric
        end

        it ':backtrace_level' do
          SemanticLogger.stub(:backtrace_level_index, 0) do
            assert_equal 'result', logger.send(measure_level, 'hello world') { 'result' }

            assert log = log_message
            assert log.backtrace
            assert log.backtrace.size > 0

            # Extract file name and line number from backtrace
            h = log.to_h
            assert_match /measure_test.rb/, h[:file], h
            assert h[:line].is_a?(Integer)
          end
        end
      end

      describe "#measure(#{level})" do
        it ':message' do
          assert_equal 'result', logger.measure(level, 'hello world') { 'result' }

          assert log = log_message
          assert_equal 'hello world', log.message
        end

        it ':level' do
          assert_equal 'result', logger.measure(level, 'hello world') { 'result' }

          assert log = log_message
          assert_equal level, log.level
        end

        it ':payload' do
          assert_equal 'result', logger.measure(level, 'hello world', payload: payload) { 'result' }

          assert log = log_message
          assert_equal payload, log.payload
        end

        describe ':min_duration' do
          it 'not log when faster' do
            assert_equal 'result', logger.measure(level, 'hello world', min_duration: 2000) { 'result' }
            refute log_message
          end

          it 'log when slower' do
            assert_equal 'result', logger.measure(level, 'hello world', min_duration: 200, payload: payload) { sleep 0.5; 'result' }
            assert log = log_message
            assert_equal 'hello world', log.message
          end
        end

        it ':exception' do
          assert_raises RuntimeError do
            logger.measure(level, 'hello world', payload: payload) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal level, log.level
        end

        it ':on_exception_level' do
          assert_raises RuntimeError do
            logger.measure(level, 'hello world', payload: payload, on_exception_level: :fatal) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal :fatal, log.level
        end

        it ':metric' do
          metric_name = '/my/custom/metric'
          assert_equal 'result', logger.measure(level, 'hello world', metric: metric_name) { 'result' }

          assert log = log_message
          assert_equal metric_name, log.metric
        end

        it ':backtrace_level' do
          SemanticLogger.stub(:backtrace_level_index, 0) do
            assert_equal 'result', logger.measure(level, 'hello world') { 'result' }

            assert log = log_message
            assert log.backtrace
            assert log.backtrace.size > 0

            # Extract file name and line number from backtrace
            h = log.to_h
            assert_match /measure_test.rb/, h[:file], h
            assert h[:line].is_a?(Integer)
          end
        end
      end

      describe "##{measure_level} keyword arguments" do
        it ':message' do
          assert_equal 'result', logger.send(measure_level, message: 'hello world') { 'result' }

          assert log = log_message
          assert_equal 'hello world', log.message
        end

        it ':level' do
          assert_equal 'result', logger.send(measure_level, message: 'hello world') { 'result' }

          assert log = log_message
          assert_equal level, log.level
        end

        it ':payload' do
          assert_equal 'result', logger.send(measure_level, message: 'hello world', payload: payload) { 'result' }

          assert log = log_message
          assert_equal payload, log.payload
        end

        describe ':min_duration' do
          it 'not log when faster' do
            assert_equal 'result', logger.send(measure_level, message: 'hello world', min_duration: 2000) { 'result' }
            refute log_message
          end

          it 'log when slower' do
            assert_equal 'result', logger.send(measure_level, message: 'hello world', min_duration: 200, payload: payload) { sleep 0.5; 'result' }

            assert log = log_message
            assert_equal 'hello world', log.message
          end
        end

        it ':exception' do
          assert_raises RuntimeError do
            logger.send(measure_level, message: 'hello world', payload: payload) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal level, log.level
        end

        it ':on_exception_level' do
          assert_raises RuntimeError do
            logger.send(measure_level, message: 'hello world', payload: payload, on_exception_level: :fatal) { raise RuntimeError.new('Test') }
          end

          assert log = log_message
          refute log.exception
          assert_equal 'hello world -- Exception: RuntimeError: Test', log.message
          assert_equal :fatal, log.level
        end

        it ':metric' do
          metric_name = '/my/custom/metric'
          assert_equal 'result', logger.send(measure_level, message: 'hello world', metric: metric_name) { 'result' }

          assert log = log_message
          assert_equal metric_name, log.metric
        end

        it ':backtrace_level' do
          SemanticLogger.stub(:backtrace_level_index, 0) do
            assert_equal 'result', logger.send(measure_level, message: 'hello world') { 'result' }

            assert log = log_message
            assert log.backtrace
            assert log.backtrace.size > 0

            # Extract file name and line number from backtrace
            h = log.to_h
            assert_match /measure_test.rb/, h[:file], h
            assert h[:line].is_a?(Integer)
          end
        end
      end

    end

    describe 'return' do
      it 'log when the block performs a return' do
        assert_equal 'Good', function_with_return(logger)

        assert log = log_message
        assert_equal 'hello world', log.message
      end
    end

    describe ':silence' do
      it 'silences messages' do
        SemanticLogger.default_level = :info
        logger.measure_info('hello world', silence: :error) do
          logger.warn "don't log me"
        end

        assert log = log_message
        assert_equal 'hello world', log.message
      end

      it 'does not silence higher level messages' do
        SemanticLogger.default_level = :info
        first                        = nil
        logger.measure_info('hello world', silence: :trace) do
          logger.debug('hello world', payload) { 'Calculations' }
          first = log_message
        end
        assert_equal 'hello world -- Calculations', first.message
        assert_equal payload, first.payload

        SemanticLogger.flush
        assert log = appender.message
        assert_equal 'hello world', log.message
      end
    end

    # Make sure that measure still logs when a block uses return to return from
    # a function
    def function_with_return(logger)
      logger.measure_info('hello world', payload: payload) do
        return 'Good'
      end
      'Bad'
    end

  end
end
