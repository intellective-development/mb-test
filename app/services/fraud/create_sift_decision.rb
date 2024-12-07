module Fraud
  class CreateSiftDecision
    def initialize(entity, decision)
      @entity   = entity
      @decision = decision

      load_subject
    end

    def call
      if @subject.nil?
        Rails.logger.warn "Unable to find subject for Sift decision with entity: #{@entity}"
        return
      end

      if @subject.sift_decision
        @subject.sift_decision.update!(decision_id: @decision[:id]) unless @decision[:id] == @subject.sift_decision.decision_id && @entity[:type] != 'user'
      else
        @subject.create_sift_decision!(decision_id: @decision[:id])
      end
    end

    private

    def load_subject
      @subject = if @entity[:type] == 'user'
                   User.includes(:sift_decision).find_by(referral_code: @entity[:id])
                 else
                   Order.includes(:sift_decision).find_by(number: @entity[:id])
                 end
    end
  end
end
