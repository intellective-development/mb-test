class WorkerException < StandardError
  class RetryableException < WorkerException; end
end
