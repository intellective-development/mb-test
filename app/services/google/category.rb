module Google
  class Category
    # source: https://www.google.com/basepages/producttype/taxonomy.en-US.txt
    CATEGORIES = {
      general_alcohol: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages',
      beer: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Beer',
      flavored: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Flavored Alcoholic Beverages',
      brandy: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Brandy',
      gin: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Gin',
      rum: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Rum',
      tequila: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Tequila',
      vodka: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Vodka',
      whiskey: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Whiskey',
      wine: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Wine',
      snacks: 'Food, Beverages & Tobacco > Food Items > Snack Foods',
      other_liquors: 'Food, Beverages & Tobacco > Beverages > Alcoholic Beverages > Liquor & Spirits > Liqueurs',
      party_supplies: 'Arts & Entertainment > Party & Celebration > Party Supplies'
    }.freeze

    def self.get(category, subtype)
      return CATEGORIES[:beer] if category == 'beer'
      return CATEGORIES[:wine] if category == 'wine'
      return CATEGORIES[:vodka] if subtype == 'vodka'
      return CATEGORIES[:whiskey] if %w[scotch whiskey].include?(subtype)
      return CATEGORIES[:tequila] if subtype == 'tequila'
      return CATEGORIES[:gin] if subtype == 'gin'
      return CATEGORIES[:rum] if subtype == 'rum'
      return CATEGORIES[:brandy] if subtype == 'brandy'
      return CATEGORIES[:flavored] if subtype == 'flavored'
      return CATEGORIES[:snacks] if subtype == 'snacks'
      return CATEGORIES[:party_supplies] if subtype == 'accessories & party supplies'
      return CATEGORIES[:other_liquors] if subtype == 'other liquors'

      CATEGORIES[:general_alcohol]
    end
  end
end
