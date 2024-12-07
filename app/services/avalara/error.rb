module Avalara
  module Error
    class StandardError < ::StandardError; end
    class FatalError < ::StandardError; end
  end
end
