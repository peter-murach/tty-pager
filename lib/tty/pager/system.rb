# frozen_string_literal: true

require 'tty-which'

module TTY
  class Pager
    # A system pager is used  on systems where native
    # pagination exists
    #
    # @api public
    class SystemPager < Pager
      # Check if command exists
      #
      # @example
      #   command_exists?('less) # => true
      #
      # @param [String] command
      #   the command to check
      #
      # @return [Boolean]
      #
      # @api private
      def self.command_exists?(command)
        TTY::Which.exist?(command)
      end

      # List possible executables for output paging
      #
      # @return [Array[String]]
      #
      # @api private
      def self.executables
        [ENV['GIT_PAGER'], ENV['PAGER'],
         command_exists?('git') ? `git config --get-all core.pager` : nil,
         'less', 'more', 'cat', 'pager', 'pg', 'most'].compact
      end

      # Find first available termainal pager program executable
      #
      # @example Basic usage
      #   find_executable # => 'less'
      #
      # @example Usage with commands
      #   find_executable('less', 'cat')  # => 'less'
      #
      # @param [Array[String]] commands
      #
      # @return [String, nil]
      #   the found executable or nil when not found
      #
      # @api public
      def self.find_executable(*commands)
        execs = commands.empty? ? executables : commands
        execs
          .compact.map(&:strip).reject(&:empty?).uniq
          .find { |cmd| command_exists?(cmd.split.first) }
      end

      # Check if command is available
      #
      # @example Basic usage
      #   available?  # => true
      #
      # @example Usage with command
      #   available?('less') # => true
      #
      # @return [Boolean]
      #
      # @api public
      def self.available?(*commands)
        !find_executable(*commands).nil?
      end

      # Create a system pager
      #
      # @param [Hash] options
      # @option options [String] :command
      #   the command to use for paging
      #
      # @api public
      def initialize(options = {})
        super
        @pager_command = options[:command]
        unless self.class.available?
          raise TTY::Pager::Error, "#{self.class.name} cannot be used on your" \
                                   " system due to lack of appropriate pager" \
                                   " executable. Install `less` like pager or" \
                                   " try using `BasicPager` instead." \
        end
      end

      # Use system command to page output text
      #
      # @example
      #   page('some long text...')
      #
      # @param [String] text
      #   the text to paginate
      #
      # @return [Boolean]
      #   the success status of launching a process
      #
      # @api public
      def page(text, &callback)
        return text unless output.tty?

        write_io = open("|#{pager_command}", 'w')
        pid      = write_io.pid

        write_io.write(text)
        write_io.close

        _, status = Process.waitpid2(pid, Process::WNOHANG)
        status.success?
      rescue Errno::ECHILD
        # on jruby 9x waiting on pid raises
        true
      end

      # The pager command to run
      #
      # @return [String]
      #   the name of executable to run
      #
      # @api private
      def pager_command(*commands)
        @pager_command = if @pager_command && commands.empty?
                           @pager_command
                         else
                           self.class.find_executable(*commands)
                         end
      end
    end # SystemPager
  end # Pager
end # TTY
