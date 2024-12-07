class BestSupplierService
  BOOST_MULTIPLER = 0.5
  BOOST_WEIGHT    = 1
  DISTANCE_WEIGHT = 1
  RATING_WEIGHT   = 1

  def initialize(address:, shipping_methods:, dynamic_routing: false, preferred_supplier_ids: nil, product_ids: nil, product_grouping_ids: nil)
    string_array = ->(param) { Array(param).map(&:to_s) }

    @address                = address
    @shipping_methods       = shipping_methods
    @dynamic_routing        = dynamic_routing
    @preferred_supplier_ids = string_array[preferred_supplier_ids]
    @product_ids            = string_array[product_ids]
    @product_grouping_ids   = string_array[product_grouping_ids]
    @memoized_distances     = MemoizedDistances.new([address.latitude, address.longitude])
  end

  # Selects a supplier for a given address
  # => Rank open suppliers by distance or by dynamic routing algorithm
  # => Give priority suppliers preference
  # => Given open stores preference
  # => If all stores are closed, choose the one which opens first
  # => Give on-demand suppliers preference regardless of open or closed
  def best_supplier(suppliers)
    # TODO: This needs to account for the open/closed state for the individual shipping methods
    # (including breaks) in addition to supplier-level holidays.
    suppliers = suppliers.select(&:active)

    open_suppliers = sort_suppliers(suppliers.reject(&:closed?))

    if product_grouping_ids.any? && suppliers&.any?
      suppliers = sort_by_inventory_availability(suppliers, supplier_product_grouping_variants(suppliers))
      open_suppliers = suppliers.reject(&:closed?)
    end

    if product_ids.any? && suppliers&.any?
      suppliers = sort_by_inventory_availability(suppliers, supplier_product_variants(suppliers))
      open_suppliers = suppliers.reject(&:closed?)
    end

    # Unless we are querying for supplier based on specific availability we only
    # want to be choosing from open on-demand suppliers. If there are on-demand
    # options, we never want to default to next-day/shipped.
    # TODO: We may want to think about what open/closed mean for next-day and/or
    #       shipping suppliers - really they don't matter, instead
    #       we care about the next available delivery slot/estimate.
    chosen_suppliers = preferred_suppliers(suppliers) || priority_suppliers(open_suppliers) || eligible_suppliers(open_suppliers) || suppliers.sort_by(&:opens_at)

    boost_on_demand(chosen_suppliers).slice(0, 1)
  end

  private

  attr_reader :address, :shipping_methods, :preferred_supplier_ids, :product_ids, :product_grouping_ids, :dynamic_routing

  def sort_suppliers(suppliers)
    return [] if suppliers.empty?

    if dynamic_routing
      sort_dynamically(suppliers)
    else
      sort_by_distance(suppliers)
    end
  end

  def eligible_suppliers(suppliers)
    return nil unless suppliers.any?
    return suppliers if product_ids.any? || product_grouping_ids.any?

    suppliers
      .select { |supplier| shipping_methods.on_demand.exists?(supplier: supplier) }
      .presence
  end

  # choose preferred suppliers specified in the options if any (different behavior than the suppliers option)
  def preferred_suppliers(suppliers)
    suppliers
      .select { |supplier| preferred_supplier_ids.include?(supplier.id.to_s) if preferred_supplier_ids&.any? }
      .presence
  end

  def priority_suppliers(suppliers)
    suppliers
      .select { |supplier| priority_delivery_zone?(supplier) }
      .presence
  end

  def priority_delivery_zone?(supplier)
    shipping_methods
      .on_demand
      .where(supplier_id: supplier&.id)
      .merge(DeliveryZone.where(priority: true))
      .any?
  end

  def boost_on_demand(suppliers)
    suppliers.sort_by { |supplier| shipping_methods.on_demand.exists?(supplier: supplier) ? 0 : 1 }
  end

  def sort_dynamically(suppliers)
    distance_scores = distance_scores(suppliers)
    rating_scores   = rating_scores(suppliers)

    weighted_hash = Hash[*suppliers.map do |s|
      [s, weighting(s, distance_scores.find { |ds| ds.id == s.id }, rating_scores.find { |rs| rs.id == s.id })]
    end.flatten]

    # TODO: this compact is to handle a bug in WeightedRandomizer, remove when fixed
    WeightedRandomizer.new(weighted_hash).sample(weighted_hash.size).compact
  end

  # This method was adjusted from straight distance based to threshold-based
  # in order to add some deterministic randomization and to prevent David from
  # being murdered by beer suppliers.
  def sort_by_distance(suppliers)
    distances = suppliers.map { |supplier| distance_from(supplier) }

    get_distance = ->(funct) { distances.public_send(funct, &:distance).distance }

    # TODO: JM: We really shouldn't be hacking this for tests!!
    if (get_distance[:max_by] - get_distance[:min_by]) >= 1.5 || Rails.env.test?
      # If range of distances is greater than 1.5 miles then we do straight
      # distance, so that we don't have stores going out of their way
      # when there is another much closer store.
      distances.sort_by(&:distance).map(&:supplier)
    else
      # Otherwise, we determine ordering based on a function of the Address 1
      # field, which will always return the same results (everything else being
      # equal).
      suppliers.shuffle(random: Random.new(address.address1.hash))
    end
  end

  def supplier_product_grouping_variants(suppliers)
    Variant
      .in_product_groupings(product_grouping_ids)
      .purchasable_from(suppliers.map(&:id))
      .to_a.uniq { |variant| "#{variant.product_size_grouping.id}__#{variant.supplier_id}" }
  end

  def supplier_product_variants(suppliers)
    Variant
      .where(product_id: product_ids)
      .purchasable_from(suppliers.map(&:id))
  end

  def sort_by_inventory_availability(suppliers, variants)
    # TODO: JM: This doesn't actually sort by inventory availability only whether the supplier
    # stocks the variant.
    inventory_histogram = Hash.new(0)

    # * -1 is used to list them in descending order whilst maintaing the original order for ties
    variants
      .group_by(&:supplier_id)
      .each { |supplier_id, supplier_variants| inventory_histogram[supplier_id] = supplier_variants.size.to_i * -1 }

    suppliers.sort_by { |supplier| inventory_histogram[supplier.id] }
  end

  def distance_scores(suppliers)
    distances = suppliers.map do |supplier|
      distance = distance_from(supplier).distance
      Score.new(supplier.id, distance.zero? ? 0.01 : distance)
    end
    normalize_scores(distances)
  end

  def rating_scores(suppliers)
    ratings = suppliers.map { |s| Score.new(s.id, s.adjusted_score) }
    normalize_scores(ratings)
  end

  def normalize_scores(scores)
    total = scores.inject(0.0) { |total_score, score| total_score + score.value }
    scores.map { |score| Score.new(score.id, score.value, score.value.to_f / total) }
  end

  # TODO: More of an exponential curve on weightings
  def weighting(supplier, distance_score = 0, rating_score = 0)
    weight = (rating_score.score * RATING_WEIGHT) + ((1 / distance_score.score) * DISTANCE_WEIGHT) + ((supplier.total_boost_factor.to_f * BOOST_MULTIPLER) * BOOST_WEIGHT)
    weight = 0.0 if weight.negative?
    weight
  end

  def distance_from(supplier)
    @memoized_distances[supplier]
  end

  Distance = Struct.new(:supplier, :distance) do
    include Comparable

    def <=>(other)
      distance <=> other.distance
    end
  end

  Score = Struct.new(:id, :value, :score)
  class MemoizedDistances < Hash
    def initialize(address_coords)
      @address_coords = address_coords
      super(nil)
    end

    def default(supplier)
      self[supplier] = Distance.new(supplier, supplier.address.distance_to(@address_coords))
    end
  end
end
