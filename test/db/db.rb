# frozen_string_literal: true

require 'fileutils'

module OpenStaxTransactionRetry
  module Test
    module Db
      def self.connect_to_mysql2
        ::ActiveRecord::Base.establish_connection(
          adapter: 'mysql2',
          database: 'transaction_retry_test',
          username: ENV.fetch('DB_USERNAME'),
          password: ENV.fetch('DB_PASSWORD', nil)
        )
      end

      def self.connect_to_postgresql
        ::ActiveRecord::Base.establish_connection(
          adapter: 'postgresql',
          database: ENV.fetch('DB_NAME', nil),
          user: ENV.fetch('DB_USERNAME', nil),
          password: ENV.fetch('DB_PASSWORD', nil)
        )
      end

      def self.connect_to_sqlite3
        ActiveRecord::Base.establish_connection(
          adapter: 'sqlite3',
          database: ':memory:',
          verbosity: 'silent'
        )
      end
    end
  end
end
