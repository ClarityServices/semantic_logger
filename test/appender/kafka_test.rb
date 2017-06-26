require_relative '../test_helper'

module Appender
  class KafkaTest < Minitest::Test
    describe SemanticLogger::Appender::Kafka do
      before do
        @appender = SemanticLogger::Appender::Kafka.new(
          seed_brokers: ['http://localhost:9092']
        )
        @message  = 'AppenderKafkaTest log message'
      end

      after do
        @appender.close if @appender
      end

      it 'sends log messages in JSON format' do
        message = nil
        options = nil
        ::Kafka::Producer.stub_any_instance(:produce, -> value, **opts { message = value; options = opts }) do
          @appender.info(@message)
          @appender.flush
        end

        h = JSON.parse(message)
        assert_equal 'info', h['level']
        assert_equal @message, h['message']
        assert_equal "SemanticLogger::Appender::Kafka", h['name']
        assert_equal $$, h['pid']

        assert_equal 'log_messages', options[:topic]
      end

    end
  end
end
