class SupplierQuality
  ALL_RATIOS = {
    wine: 0.65,
    liquor: 0.2,
    beer: 0.1,
    cider: 0.025,
    mixers: 0.025
  }.freeze

  CATEGORY_GOALS = {
    wine: 270, # 1
    liquor: 385, # 63
    beer: 350, # 2441
    cider: 30, # 2220
    mixers: 150 # 2703
  }.freeze

  TYPE_GOALS = {
    # wine
    red: 135, # 11
    white: 82, # 42
    rose: 10, # 33
    sparkling: 32, # 37
    dessert: 1, # 2
    # liquor
    vodka: 78, # 65
    whiskey: 75, # 64
    scotch: 46, # 68
    tequila: 40, # 67
    rum: 40, # 69
    gin: 30, # 70
    brandy: 12, # 71
    vermouth: 18, # 145
    liqueur: 20, # 144
    other_liquors: 65, # 66
    # beer
    domestic: 200,
    imported: 150
  }.freeze

  def self.selection_score(supplier_id)
    supplier = Supplier.find(supplier_id)
    if supplier
      category_scores = category_scores(supplier)
      { score: scale_score(category_scores), categories: category_scores, types: category_scores(supplier) }
    end
  end

  def self.category_scores(supplier)
    supplier_categories(supplier).map do |category|
      goal = CATEGORY_GOALS[category.name.to_sym]
      context = { name: category.name, types: type_scores(supplier, category) }
      context.merge!(count_score(goal, category.id, supplier.id))
    end
  end

  def self.type_scores(supplier, category)
    types = category.children
    type_scores = types.map do |type|
      goal = begin
        TYPE_GOALS[type.name.to_sym]
      rescue StandardError
        nil
      end
      count_score(goal, type.id, supplier.id).merge!(name: type.name) if goal
    end
    type_scores.compact
  end

  def self.supplier_categories(supplier)
    supplier_type = supplier.supplier_type.try(:name)
    supplier_state = supplier.address.try(:state_name)

    categories = ProductType.root
    if supplier_state == 'NY' && supplier_type == 'Wine & Spirits'
      categories = categories.where(name: %w[wine liquor])
    elsif supplier_state == 'NY' && supplier_type == 'Beer & Mixers'
      categories = categories.where(name: %w[beer cider mixers])
    end

    categories.select { |pt| CATEGORY_GOALS.key?(pt.name.to_sym) } # ensure it's one we care about
  end

  def self.scale_score(category_scores)
    score_total = 0
    ratio_total = 0
    category_scores.each do |score|
      score_total += (score[:score] * ALL_RATIOS[score[:name].to_sym])
      ratio_total += ALL_RATIOS[score[:name].to_sym]
    end
    score_total / ratio_total # scale if not all types present
  end

  # scores
  def self.count_score(goal, type_id, supplier_id)
    count = products_of_type_family(type_id, supplier_id).size
    { count: count, score: score_from_ratio(count, goal) }
  end

  # types
  def self.products_of_type_family(type_id, supplier_id)
    descendant_ids = ProductType.find(type_id).try(:descendent_ids)
    products_of_type(descendant_ids, supplier_id)
  end

  def self.products_of_type(type_id, supplier_id)
    Variant.joins(:product_size_grouping).active.available.where(supplier_id: supplier_id).where('product_groupings.product_type_id IN (?)', type_id)
  end

  def self.score_from_ratio(total, expected)
    total && expected ? score_func(total.to_f / expected) : nil
  end

  def self.score_func(count) # scale 100
    100 * (-1.0 / (count * count * 10 + 1) + 1)
  end
end
