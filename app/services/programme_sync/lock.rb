require "zlib"

class ProgrammeSync
  class Lock
    KEY = Zlib.crc32("programme_sync").freeze

    class << self
      def with_lock
        acquired = acquire
        return false unless acquired

        yield
      ensure
        release if acquired
      end

      private

      def acquire
        ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{KEY})")
      end

      def release
        ActiveRecord::Base.connection.select_value("SELECT pg_advisory_unlock(#{KEY})")
      end
    end
  end
end
