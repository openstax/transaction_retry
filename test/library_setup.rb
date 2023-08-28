# frozen_string_literal: true

# Prepares application to be tested (requires files, connects to db, resets schema and data, applies patches, etc.)

# Initialize database
require 'db/all'

case ENV.fetch('db', 'sqlite3')
when 'mysql2'
  OpenStaxTransactionRetry::Test::Db.connect_to_mysql2
when 'postgresql'
  OpenStaxTransactionRetry::Test::Db.connect_to_postgresql
when 'sqlite3'
  OpenStaxTransactionRetry::Test::Db.connect_to_sqlite3
else
  raise "Unknown database: #{ENV.fetch('db', nil)}"
end

require 'logger'
ActiveRecord::Base.logger = Logger.new(File.expand_path("#{File.dirname(__FILE__)}/log/test.log"))

OpenStaxTransactionRetry::Test::Migrations.run!

# Load the code that will be tested
require 'open_stax_transaction_retry'

OpenStaxTransactionRetry.apply_activerecord_patch
