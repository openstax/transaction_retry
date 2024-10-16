# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'open_stax_transaction_retry/version'

Gem::Specification.new do |s|
  s.name        = 'openstax_transaction_retry'
  s.version     = OpenStaxTransactionRetry::VERSION
  s.authors     = ['Nathan Stitt', 'Optimal Workshop', 'Piotr \'Qertoip\' Włodarek']
  s.email       = []
  s.homepage    = 'https://github.com/openstax/transaction_retry'
  s.summary     = 'Retries database transaction on deadlock and transaction serialization errors. Supports MySQL, PostgreSQL and SQLite.'
  s.description = 'Retries database transaction on deadlock and transaction serialization errors. Supports MySQL, PostgreSQL and SQLite (as long as you are using new drivers mysql2, pg, sqlite3).'
  s.required_ruby_version = '>= 3'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f == 'd' || f.start_with?('test') }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activerecord', '>= 6'
  s.add_runtime_dependency 'openstax_transaction_isolation', '>= 2'
  s.metadata['rubygems_mfa_required'] = 'true'
end
