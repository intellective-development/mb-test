class OrderVerificationService
  class << self
    def emit_fraud_metric(decision)
      is_legit = Sift::Decision::PAYMENT_ABUSE_NEGATIVE_DECISION_IDS.include?(decision) ? 0 : 1

      MetricsClient::Metric.emit('minibar_web.sift.order_verification_service.decision.legit', is_legit)
      MetricsClient::Metric.emit("minibar_web.sift.order_verification_service.decision.#{decision}", 1)
    end

    def verify(order)
      # Make transition 'verifying' -> 'paid' synchronous to avoid race conditions between Sift and our workers
      # (Previously: worker -> workflow -> webhook -> worker)
      workflow_result = Fraud::CreateOrderEvent.new(order).call_and_run_workflow
      score, decision = workflow_result.values_at(:score, :decision)

      # Limit Sift's decision to current order
      case decision
      when 'order_looks_bad_payment_abuse', 'looks_bad_payment_abuse'
        Fraud::CreateSiftDecision.new({ type: 'order', id: order.number }, { id: 'order_looks_bad_payment_abuse' }).call
      when 'order_looks_ok_payment_abuse', 'looks_ok_payment_abuse'
        Fraud::CreateSiftDecision.new({ type: 'order', id: order.number }, { id: 'order_looks_ok_payment_abuse' }).call
      when 'storefront_fraud_bypass_payment_abuse'
        Fraud::CreateSiftDecision.new({ type: 'order', id: order.number }, { id: decision }).call
      else
        # Force transition: do not wait for async decision to be taken (e.g. link down with Sift, review queue)
        Order::PayTransitionWorker.perform_async(order.id)
      end

      emit_fraud_metric(decision)
    end
  end
end
