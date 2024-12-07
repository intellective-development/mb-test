class Order::Hasher
  def initialize(order:)
    @order = order
  end

  def encode
    original_hash
  end

  def hash_valid?(hash)
    hash == original_hash
  end

  private

  attr_reader :order

  def original_hash
    @original_hash ||= Digest::SHA256.hexdigest((order.number.to_i + order.user.created_at.to_i).to_s)
  end
end
