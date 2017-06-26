# Load AwesomePrint if available
begin
  require 'awesome_print'
rescue LoadError
end

module SemanticLogger
  module Formatters
    class Color < Default
      attr_accessor :color_map, :color

      # Supply a custom color map for every log level
      class ColorMap
        attr_accessor :trace, :debug, :info, :warn, :error, :fatal, :bold, :clear

        def initialize(trace: AnsiColors::MAGENTA, debug: AnsiColors::GREEN, info: AnsiColors::CYAN, warn: AnsiColors::BOLD, error: AnsiColors::RED, fatal: AnsiColors::RED, bold: AnsiColors::BOLD, clear: AnsiColors::CLEAR)
          @trace = trace
          @debug = debug
          @info  = info
          @warn  = warn
          @error = error
          @fatal = fatal
          @bold  = bold
          @clear = clear
        end

        def [](level)
          public_send(level)
        end
      end

      # Adds color to the default log formatter
      #
      # Example:
      #   # Use a colorized output logger.
      #   SemanticLogger.add_appender(io: $stdout, formatter: :color)
      #
      # Example:
      #   # Use a colorized output logger chenging the color for info to green.
      #   SemanticLogger.add_appender(io: $stdout, formatter: :color, color_map: {info: SemanticLogger::AnsiColors::YELLOW})
      #
      # Parameters:
      #  ap: [Hash]
      #    Any valid AwesomePrint option for rendering data.
      #    These options can also be changed be creating a `~/.aprc` file.
      #    See: https://github.com/michaeldv/awesome_print
      #
      #    Note: The option :multiline is set to false if not supplied.
      #    Note: Has no effect if Awesome Print is not installed.
      #
      #  color_map: [Hash | SemanticLogger::Formatters::Color::ColorMap]
      #    ColorMaps each of the log levels to a color
      def initialize(ap: {multiline: false}, color_map: ColorMap.new, time_format: TIME_FORMAT, log_host: false, log_application: false)
        @ai_options = ap
        @color_map  = color_map.is_a?(ColorMap) ? color_map : ColorMap.new(color_map)
        super(time_format: time_format, log_host: log_host, log_application: log_application)
      end

      def level
        "#{color}#{super}#{color_map.clear}"
      end

      def tags
        "[#{color}#{log.tags.join("#{color_map.clear}] [#{color}")}#{color_map.clear}]" if log.tags && !log.tags.empty?
      end

      # Named Tags
      def named_tags
        if (named_tags = log.named_tags) && !named_tags.empty?
          list = []
          named_tags.each_pair { |name, value| list << "#{color}#{name}: #{value}#{color_map.clear}" }
          "{#{list.join(', ')}}"
        end
      end

      def duration
        "(#{color_map.bold}#{log.duration_human}#{color_map.clear})" if log.duration
      end

      def name
        "#{color}#{super}#{color_map.clear}"
      end

      def payload
        return unless log.has_payload?

        if !defined?(AwesomePrint) || !log.payload.respond_to?(:ai)
          super
        else
          "-- #{log.payload.ai(@ai_options)}" rescue super
        end
      end

      def exception
        "-- Exception: #{color}#{log.exception.class}: #{log.exception.message}#{color_map.clear}\n#{log.backtrace_to_s}" if log.exception
      end

      def call(log, logger)
        self.color = color_map[log.level]
        super(log, logger)
      end

    end
  end
end

