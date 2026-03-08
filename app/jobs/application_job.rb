class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Discard jobs when the underlying record has been deleted
  discard_on ActiveJob::DeserializationError
end
