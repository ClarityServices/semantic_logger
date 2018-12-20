require_relative '../test_helper'
require 'stringio'

# Unit Test for SemanticLogger::Appender::File
#
module Appender
  class FileTest < Minitest::Test
    describe SemanticLogger::Appender::File do
      before do
        SemanticLogger.default_level   = :trace
        SemanticLogger.backtrace_level = :error
        @time                          = Time.new
        @io                            = StringIO.new
        @appender                      = SemanticLogger::Appender::File.new(io: @io)
        @hash                          = {session_id: 'HSSKLEU@JDK767', tracking_number: 12_345}
        @hash_str                      = @hash.inspect.sub('{', '\\{').sub('}', '\\}')
        @thread_name                   = Thread.current.name
        @file_name_reg_exp             = RUBY_VERSION.to_f <= 2.0 ? ' (mock|file_test).rb:\d+' : ' file_test.rb:\d+'
        @pid_regexp                    = defined?(JRuby) ? '' : '\d+:'
      end

      describe 'format logs into text form' do
        it 'handle no message or payload' do
          @appender.debug
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File\n/, @io.string)
        end

        it 'handle message' do
          @appender.debug 'hello world'
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- hello world\n/, @io.string)
        end

        it 'handle message and payload' do
          @appender.debug 'hello world', @hash
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- hello world -- #{@hash_str}\n/, @io.string)
        end

        it 'handle message, payload, and exception' do
          @appender.debug 'hello world', @hash, StandardError.new('StandardError')
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- hello world -- #{@hash_str} -- Exception: StandardError: StandardError\n\n/, @io.string)
        end

        it 'logs exception with nil backtrace' do
          @appender.debug StandardError.new('StandardError')
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- Exception: StandardError: StandardError\n\n/, @io.string)
        end

        it 'handle nested exception' do
          begin
            raise StandardError, 'FirstError'
          rescue Exception
            begin
              raise StandardError, 'SecondError'
            rescue Exception => e2
              @appender.debug e2
            end
          end
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name} file_test.rb:\d+\] SemanticLogger::Appender::File -- Exception: StandardError: SecondError\n/, @io.string)
          assert_match(/^Cause: StandardError: FirstError\n/, @io.string) if Exception.instance_methods.include?(:cause)
        end

        it 'logs exception with empty backtrace' do
          exc = StandardError.new('StandardError')
          exc.set_backtrace([])
          @appender.debug exc
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ D \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- Exception: StandardError: StandardError\n\n/, @io.string)
        end

        it 'ignores metric only messages' do
          @appender.debug metric: 'my/custom/metric'
          assert_equal '', @io.string
        end

        it 'ignores metric only messages with payload' do
          @appender.debug metric: 'my/custom/metric', payload: {hello: :world}
          assert_equal '', @io.string
        end
      end

      describe 'for each log level' do
        # Ensure that any log level can be logged
        SemanticLogger::LEVELS.each do |level|
          it "log #{level} with file_name" do
            SemanticLogger.stub(:backtrace_level_index, 0) do
              @appender.send(level, 'hello world', @hash)
              assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ \w \[#{@pid_regexp}#{@thread_name}#{@file_name_reg_exp}\] SemanticLogger::Appender::File -- hello world -- #{@hash_str}\n/, @io.string)
            end
          end

          it "log #{level} without file_name" do
            SemanticLogger.stub(:backtrace_level_index, 100) do
              @appender.send(level, 'hello world', @hash)
              assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ \w \[#{@pid_regexp}#{@thread_name}\] SemanticLogger::Appender::File -- hello world -- #{@hash_str}\n/, @io.string)
            end
          end
        end
      end

      describe 'custom formatter' do
        before do
          @appender = SemanticLogger::Appender::File.new(io: @io) do |log|
            tags = log.tags.collect { |tag| "[#{tag}]" }.join(' ') + ' ' if log.tags&.size&.positive?

            message = log.message.to_s
            message << ' -- ' << log.payload.inspect if log.payload
            message << ' -- ' << "#{log.exception.class}: #{log.exception.message}\n#{(log.exception.backtrace || []).join("\n")}" if log.exception

            duration_str = log.duration ? " (#{format('%.1f', log.duration)}ms)" : ''

            "#{log.formatted_time} #{log.level.to_s.upcase} [#{$$}:#{log.thread_name}] #{tags}#{log.name} -- #{message}#{duration_str}"
          end
        end

        it 'format using formatter' do
          @appender.debug
          assert_match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ DEBUG \[\d+:#{@thread_name}\] SemanticLogger::Appender::File -- \n/, @io.string)
        end
      end
    end
  end
end
