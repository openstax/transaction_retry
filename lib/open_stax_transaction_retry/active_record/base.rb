# frozen_string_literal: true

require 'active_record/base'

module OpenStaxTransactionRetry
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          class << self
            alias_method :transaction_without_retry, :transaction
            alias_method :transaction, :transaction_with_retry
          end
        end
      end

      module ClassMethods
        # rubocop:todo Metrics/PerceivedComplexity
        def transaction_with_retry(*objects, &block) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          retry_count = 0

          opts = if objects.last.is_a? Hash
                   objects.last
                 else
                   {}
                 end

          retry_on = opts.delete(:retry_on)
          max_retries = opts.delete(:max_retries) || OpenStaxTransactionRetry.max_retries

          begin
            transaction_without_retry(*objects, &block)
          rescue ::ActiveRecord::TransactionIsolationConflict, *retry_on => e
            raise if retry_count >= max_retries
            raise if tr_in_nested_transaction?

            retry_count += 1
            logger&.warn "#{e.class.name} detected. Retry num #{retry_count}..."
            before_retry&.call(retry_count, e)
            tr_exponential_pause(retry_count)
            retry
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity

        private

        # Sleep 0, 1, 2, 4, ... seconds up to the OpenStaxTransactionRetry.max_retries.
        # Cap the sleep time at 32 seconds.
        # An ugly tr_ prefix is used to minimize the risk of method clash in the future.
        def tr_exponential_pause(count)
          seconds = OpenStaxTransactionRetry.wait_times[count - 1] || 32

          if OpenStaxTransactionRetry.fuzz
            fuzz_factor = [seconds * 0.25, 1].max

            seconds += (rand * (fuzz_factor * 2)) - fuzz_factor
          end

          sleep(seconds) if seconds.positive?
        end

        # Returns true if we are in the nested transaction (the one with :requires_new => true).
        # Returns false otherwise.
        # An ugly tr_ prefix is used to minimize the risk of method clash in the future.
        def tr_in_nested_transaction?
          connection.open_transactions != 0
        end
      end
    end
  end
end

ActiveRecord::Base.include OpenStaxTransactionRetry::ActiveRecord::Base
