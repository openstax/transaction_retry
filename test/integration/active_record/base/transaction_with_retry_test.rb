# frozen_string_literal: true

require 'test_helper'

class TransactionWithRetryTest < Minitest::Test
  class CustomError < StandardError
  end

  def setup
    @original_max_retries = OpenStaxTransactionRetry.max_retries
    @original_wait_times = OpenStaxTransactionRetry.wait_times
    @original_retry_on = OpenStaxTransactionRetry.retry_on
    @original_before_retry = OpenStaxTransactionRetry.before_retry
  end

  def teardown
    OpenStaxTransactionRetry.max_retries = @original_max_retries
    OpenStaxTransactionRetry.wait_times = @original_wait_times
    OpenStaxTransactionRetry.retry_on = @original_retry_on
    OpenStaxTransactionRetry.before_retry = @original_before_retry
    QueuedJob.delete_all
  end

  def test_does_not_break_transaction
    ActiveRecord::Base.transaction do
      QueuedJob.create!(job: 'is fun!')
      assert_equal(1, QueuedJob.count)
    end
    assert_equal(1, QueuedJob.count)
    QueuedJob.first.destroy
  end

  def test_does_not_break_transaction_rollback
    ActiveRecord::Base.transaction do
      QueuedJob.create!(job: 'gives money!')
      raise ActiveRecord::Rollback
    end
    assert_equal(0, QueuedJob.count)
  end

  def test_retries_transaction_on_transaction_isolation_conflict
    first_run = true

    ActiveRecord::Base.transaction do
      if first_run
        first_run = false
        message = 'Deadlock found when trying to get lock'
        raise ActiveRecord::TransactionIsolationConflict, message
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal(1, QueuedJob.count)

    QueuedJob.first.destroy
  end

  def test_does_not_retry_on_unknown_error
    first_run = true

    assert_raises(CustomError) do
      ActiveRecord::Base.transaction do
        if first_run
          first_run = false
          raise CustomError, 'random error'
        end
        QueuedJob.create!(job: 'is cool!')
      end
    end
    assert_equal(0, QueuedJob.count)
  end

  def test_retries_on_custom_error
    first_run = true
    ActiveRecord::Base.transaction(retry_on: CustomError) do
      if first_run
        first_run = false
        raise CustomError, 'random error'
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal(1, QueuedJob.count)
    QueuedJob.first.destroy
  end

  def test_retries_on_configured_retry_on
    OpenStaxTransactionRetry.retry_on = CustomError
    first_run = true
    ActiveRecord::Base.transaction do
      if first_run
        first_run = false
        raise CustomError, 'random error'
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal(1, QueuedJob.count)
    QueuedJob.first.destroy
  end

  def test_retries_transaction_on_transaction_isolation_when_retry_on_set
    OpenStaxTransactionRetry.retry_on = CustomError
    first_run = true
    ActiveRecord::Base.transaction do
      if first_run
        first_run = false
        message = 'Deadlock found when trying to get lock'
        raise ActiveRecord::TransactionIsolationConflict, message
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal(1, QueuedJob.count)
    QueuedJob.first.destroy
  end

  def test_does_not_retry_transaction_more_than_max_retries_times
    OpenStaxTransactionRetry.max_retries = 1
    run = 0

    assert_raises(ActiveRecord::TransactionIsolationConflict) do
      ActiveRecord::Base.transaction do
        run += 1
        message = 'Deadlock found when trying to get lock'
        raise ActiveRecord::TransactionIsolationConflict, message
      end
    end

    assert_equal(2, run)  # normal run + one retry

    OpenStaxTransactionRetry.max_retries = 3

    run = 0

    assert_raises(ActiveRecord::TransactionIsolationConflict) do
      ActiveRecord::Base.transaction(max_retries: 1) do
        run += 1
        message = 'Deadlock found when trying to get lock'
        raise ActiveRecord::TransactionIsolationConflict, message
      end
    end

    assert_equal(2, run)  # normal run + one retry
  end

  def test_does_not_retry_nested_transaction
    first_try = true

    ActiveRecord::Base.transaction do
      assert_raises(ActiveRecord::TransactionIsolationConflict) do
        ActiveRecord::Base.transaction(requires_new: true) do
          if first_try
            first_try = false
            message = 'Deadlock found when trying to get lock'
            raise ActiveRecord::TransactionIsolationConflict, message
          end
          QueuedJob.create!(job: 'is cool!')
        end
      end
    end

    assert_equal(0, QueuedJob.count)
  end

  def test_run_custom_lambda_before_retry
    code_run = false
    retry_id = nil
    error_instance = nil
    first_try = true
    lambda_code = lambda do |retry_num, error|
      code_run = true
      retry_id = retry_num
      error_instance = error
    end

    ActiveRecord::Base.transaction(before_retry: lambda_code) do
      if first_try
        first_try = false
        raise ActiveRecord::TransactionIsolationConflict
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal 1, QueuedJob.count
    assert code_run
    assert_equal 1, retry_id
    assert_equal ActiveRecord::TransactionIsolationConflict, error_instance.class
  end

  def test_run_custom_global_lambda_before_retry
    code_run = false
    retry_id = nil
    error_instance = nil
    OpenStaxTransactionRetry.before_retry = lambda { |retry_num, error|
      code_run = true
      retry_id = retry_num
      error_instance = error
    }
    first_try = true

    ActiveRecord::Base.transaction do
      if first_try
        first_try = false
        raise ActiveRecord::TransactionIsolationConflict
      end
      QueuedJob.create!(job: 'is cool!')
    end
    assert_equal 1, QueuedJob.count
    assert code_run
    assert_equal 1, retry_id
    assert_equal ActiveRecord::TransactionIsolationConflict, error_instance.class
  end
end
