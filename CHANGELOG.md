### Unreleased

### 1.2.0 - 2023-08-24
* Forked and renamed to OpenStaxTransactionRetry
* Fix bug with calling overloaded transaction with a hash


### 1.1.0 - 2019-06-17

* Add `TransactionRetry.before_retry` configuration option to run Proc before transaction retry
* Add `TransactionRetry.retry_on` configuration option to include more Errors to retry on
* Update dependency activerecord >= 5.1
* Update dependency ruby 2.2.2
* Upgrade dependency transaction_isolation to 1.0.5
* Adapt gemspec info
* Forked gem from [transaction_retry 1.0.3](https://github.com/qertoip/transaction_retry)
