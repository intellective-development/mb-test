class Profile
  class AddProductAddToCart
    def initialize(profile_id, product_grouping_id)
      @profile = Profile.find(profile_id)
      @product_grouping = ProductSizeGrouping.find(product_grouping_id)
    end

    def call
      @profile.added_categories = @profile.added_categories | Array(@product_grouping.hierarchy_category_id)
      @profile.added_types      = @profile.added_types | Array(@product_grouping.hierarchy_type_id)
      @profile.added_subtypes   = @profile.added_subtypes | Array(@product_grouping.hierarchy_subtype_id)
      @profile.save!
    end
  end
end
