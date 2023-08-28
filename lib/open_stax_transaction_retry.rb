# frozen_string_literal: true

require 'active_record'
require 'transaction_isolation'
require_relative 'open_stax_transaction_retry/version'

module OpenStaxTransactionRetry
  # Must be called after ActiveRecord established a connection.
  # Only then we know which connection adapter is actually loaded and can be enhanced.
  # Please note ActiveRecord does not load unused adapters.
  def self.apply_activerecord_patch
    TransactionIsolation.apply_activerecord_patch
    require_relative 'open_stax_transaction_retry/active_record/base'
  end

  if defined?(::Rails)
    # Setup applying the patch after Rails is initialized.
    class Railtie < ::Rails::Railtie
      config.after_initialize do
        OpenStaxTransactionRetry.apply_activerecord_patch
      end
    end
  end

  def self.before_retry=(lambda_block)
    @@before_retry = lambda_block # rubocop:todo Style/ClassVars
  end

  def self.before_retry
    @@before_retry ||= nil # rubocop:todo Style/ClassVars
  end

  def self.retry_on=(error_classes)
    @@retry_on = Array(error_classes) # rubocop:todo Style/ClassVars
  end

  def self.retry_on
    @@retry_on ||= [] # rubocop:todo Style/ClassVars
  end

  def self.max_retries
    @@max_retries ||= 3 # rubocop:todo Style/ClassVars
  end

  def self.max_retries=(n) # rubocop:todo Naming/MethodParameterName
    @@max_retries = n # rubocop:todo Style/ClassVars
  end

  def self.wait_times
    @@wait_times ||= [0, 1, 2, 4, 8, 16, 32] # rubocop:todo Style/ClassVars
  end

  def self.wait_times=(array_of_seconds)
    @@wait_times = array_of_seconds # rubocop:todo Style/ClassVars
  end

  def self.fuzz
    @@fuzz ||= true # rubocop:todo Style/ClassVars
  end

  def self.fuzz=(val)
    @@fuzz = val # rubocop:todo Style/ClassVars
  end
end
