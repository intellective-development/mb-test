class Profile
  class AddProductImpression
    def initialize(profile_id, product_grouping_id)
      @profile = Profile.find(profile_id)
      @product_grouping = ProductSizeGrouping.find(product_grouping_id)
    end

    def call
      @profile.viewed_categories = @profile.viewed_categories | Array(@product_grouping.hierarchy_category_id)
      @profile.viewed_types      = @profile.viewed_types | Array(@product_grouping.hierarchy_type_id)
      @profile.viewed_subtypes   = @profile.viewed_subtypes | Array(@product_grouping.hierarchy_subtype_id)
      @profile.save!
    end
  end
end
