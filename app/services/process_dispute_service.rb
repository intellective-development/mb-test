class ProcessDisputeService
  attr_accessor :dispute, :existing_dispute

  def initialize(dispute)
    @dispute = dispute
    @existing_dispute = Dispute.find_by(external_id: dispute.id)
  end

  def call
    existing_dispute ? update_dispute : create_dispute
  end

  private

  def create_dispute
    order_charge = Charge.find_by(transaction_id: dispute.transaction_details.id)
    order_charge.order.disputes.create!(dispute_attrs) and return if order_charge.present?

    membership_charge = MembershipTransaction.find_by(transaction_id: dispute.transaction_details.id)
    membership_charge.membership.disputes.create!(dispute_attrs) and return if membership_charge.present?

    raise "Cannot find original transaction #{dispute.transaction_details.id} for dispute #{dispute.id}"
  end

  def dispute_attrs
    {
      kind: dispute.kind,
      reason: 'fraud',
      status: dispute.status,
      external_id: dispute.id,
      transaction_id: dispute.transaction_details.id
    }
  end

  def update_dispute
    # If the dispute exists we assume the only change will be the status
    existing_dispute.update(status: dispute.status)
  end
end
