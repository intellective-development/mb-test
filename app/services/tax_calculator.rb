# deprecated
class TaxCalculator
  include SentryNotifiable

  delegate :percentage, to: :tax_rate, allow_nil: true, prefix: true
  attr_reader :tax_rate, :tax_percent, :state, :root_type, :product, :quantity, :zip_code

  def initialize(tax_rate, price, address, product = nil, quantity = 1, variant = nil)
    @product     = product
    @variant     = variant
    @quantity    = quantity
    @root_type   = product.hierarchy_category_name.to_s.downcase if product
    @type        = product&.hierarchy_type_name&.to_s&.downcase

    @address     = address
    @state       = address&.state_name
    @zip_code    = address&.zip_code
    @tax_rate    = tax_rate
    @tax_percent = price.to_f * tax_percentage / 100.0
  end

  def tax_percentage
    @tax_percentage ||= tax_rate_percentage.to_f
  end

  def tax_charge
    return 0.0 if @variant&.tax_exempt?

    (sales_tax + local_tax).to_f.round_at(2)
  end

  # Applicable taxes per shipment
  # NY bag fee [TECH-2010]
  # Denver, CO bag fee [TECH-4822]
  def self.supplier_state_shipping_tax(supplier)
    state_abbr = supplier&.state&.abbreviation
    city = supplier&.address&.city if supplier&.address.respond_to?(:city)

    case state_abbr
    when 'NY' then 0.05
    when 'CO' then city&.casecmp?('Denver') ? 0.1 : 0.0
    when 'MD' then city&.casecmp?('Baltimore') ? 0.05 : 0.0
    else 0.0
    end
  end

  # the main difference is that it will not include illinois local tax
  def bottle_fee_charge
    return 0.0 if @variant&.tax_exempt?

    local_tax = case state
                when 'CA' then california_tax_charges
                when 'MA' then massachusetts_tax_charges
                when 'CT' then connecticut_tax_charges
                when 'NY' then new_york_tax_charges
                else 0.0
                end
    local_tax *= quantity
    local_tax
  end

  private

  # TODO: Expose these sales and local tax as public methods and store the
  # values somewhere.

  # This is the sales tax applied on an item, less any local taxes such as
  # bottle taxes, plastic bag taxes etc.
  def sales_tax
    tax_percent.to_f.round_at(2)
  end

  # This includes any additional charges applied to the order in addition to
  # the base tax rate. It includes things like bottle tax and will vary
  # based on the location (state, county, zip).
  def local_tax
    local_tax = case state
                when 'CA' then california_tax_charges
                when 'IL' then illinois_tax_charges
                when 'MA' then massachusetts_tax_charges
                when 'CT' then connecticut_tax_charges
                when 'NY' then new_york_tax_charges
                else 0.0
                end
    local_tax * quantity
  end

  # California adds CRV (common redemption value, a bottle tax) on to the
  # price of carbonated or non-carbonated water, juice, soft drinks and beer.
  # As of July 2015, CRV is 0.05 per container less than 24oz and 0.10 per
  # container 24oz and larger.
  def california_tax_charges
    amount = 0

    if @variant.present? && @variant.supplier[:custom_ca_crv]
      amount = @variant.ca_crv if @variant.ca_crv.present?
    else
      amount =  case root_type
                when 'beer', 'mixers'
                  volume = convert_to_oz(volume_value, volume_unit)
                  if volume.nil?
                    0.0 # There was an error computing the volume
                  elsif volume < 24
                    container_count * 0.05
                  else
                    container_count * 0.10
                  end
                else
                  0.0
                end
    end

    amount + (amount * (tax_percentage / 100.0))
  end

  def new_york_tax_charges
    container_type = String(@product.container_type).downcase
    return container_count * 0.05 if %w[beer mixers].include?(@root_type) && %w[can bottle].include?(container_type)

    0.0
  end

  # FIXME: Eventually it may suit us to move these to external YML files which gets
  #        loaded as needed.
  IL_CHICAGO_ZIPS = %w[60290 60601 60602 60603 60604 60605 60606 60607 60608 60610 60611 60614 60615 60618 60619 60622 60623 60624 60628 60609 60612 60613 60616 60617 60620 60621 60625 60626 60629 60630 60632 60636 60637 60631 60633 60634 60638 60641 60642 60643 60646 60647 60652 60653 60656 60660 60661 60664 60639 60640 60644 60645 60649 60651 60654 60655 60657 60659 60666 60668 60673 60677 60669 60670 60674 60675 60678 60680 60681 60682 60686 60687 60688 60689 60694 60695 60697 60699 60684 60685 60690 60691 60693 60696 60701].freeze
  IL_COOK_COUNTY_ZIPS = %w[60004 60005 60006 60007 60008 60009 60016 60017 60018 60019 60022 60025 60026 60029 60038 60043 60053 60055 60056 60062 60065 60067 60068 60070 60074 60076 60077 60078 60082 60090 60091 60093 60094 60095 60104 60107 60130 60131 60133 60141 60153 60154 60155 60159 60160 60161 60162 60163 60164 60165 60168 60169 60171 60173 60176 60179 60192 60193 60194 60195 60196 60201 60202 60203 60204 60208 60209 60296 60297 60301 60302 60303 60304 60305 60402 60406 60409 60411 60412 60415 60419 60422 60425 60426 60428 60429 60430 60438 60439 60443 60445 60452 60453 60454 60455 60456 60457 60458 60459 60461 60462 60463 60464 60465 60466 60467 60469 60471 60472 60473 60475 60476 60477 60478 60480 60482 60483 60487 60499 60501 60513 60525 60526 60534 60546 60558 60601 60602 60603 60604 60605 60606 60607 60608 60609 60610 60611 60612 60613 60614 60615 60616 60617 60618 60619 60620 60621 60622 60623 60624 60625 60626 60628 60629 60630 60631 60632 60633 60634 60636 60637 60638 60639 60640 60641 60643 60644 60645 60646 60647 60649 60651 60652 60653 60654 60655 60656 60657 60659 60660 60661 60663 60664 60666 60668 60669 60670 60673 60674 60675 60677 60678 60679 60680 60681 60682 60684 60685 60686 60687 60688 60689 60690 60691 60693 60694 60695 60696 60697 60699 60701 60706 60707 60712 60714 60803 60804 60805 60827].freeze

  IL_CHICAGO_RATES = {
    'wine' => 0.0028125,
    'liquor' => 0.0209375,
    'beer' => 0.002265625,
    'mixers' => 0.0
  }.freeze

  IL_COOK_COUNTY_RATES = {
    'wine' => 0.001875,
    'liquor' => 0.01953125,
    'beer' => 0.000703125,
    'mixers' => 0.0
  }.freeze

  def illinois_tax_rate
    city_rate = IL_CHICAGO_RATES[root_type] || 0.0
    city_rate = 0.0 unless IL_CHICAGO_ZIPS.include?(zip_code)

    county_rate = IL_COOK_COUNTY_RATES[root_type] || 0.0
    county_rate = 0.0 unless IL_COOK_COUNTY_ZIPS.include?(zip_code)

    city_rate + county_rate
  end

  def illinois_tax_charges
    taxable_volume = convert_to_oz(volume_value * container_count, volume_unit).to_f
    multiplier = illinois_tax_rate || 0.0

    taxable_volume * illinois_tax_rate
  end

  # MA imposes a 0.05 per-container charge on all carbonated soda, beer and malt beverages
  # (bottles or cans).
  def massachusetts_tax_charges
    case root_type
    when 'beer', 'mixers'
      if @type == 'cider'
        0.0
      elsif String(@product.container_type).casecmp('can') || String(@product.container_type).casecmp('bottle')
        container_count * 0.05
      else
        0.0
      end
    else
      0.0
    end
  end

  # Same as Massachusetts for "Beer, cider, malt, carbonated soft drinks, mineral water."
  def connecticut_tax_charges
    container_type = String(@product.container_type).downcase
    return container_count * 0.05 if %w[beer mixers].include?(@root_type) && %w[can bottle].include?(container_type)

    if ['liquor'].include?(@root_type) && %w[can bottle].include?(container_type)
      oz_volume = convert_to_oz(volume_value, volume_unit)
      # TECH-4925 For now we will only charge bottle fee for 50ml bottles of liquor.
      return container_count * 0.05 if oz_volume > 1.69 && oz_volume < 1.70
    end
    0.0
  end

  def container_count
    @product.container_count || 1
  end

  def volume_value
    @product.volume_value || 0.0
  end

  def volume_unit
    @product.volume_unit
  end

  UNITWISE_FL_OZ = 'oz fl'.freeze

  def convert_to_oz(value, unit)
    return if value.nil?

    unit = String(unit).downcase
    return value if unit == 'oz' || unit.blank?

    require 'unitwise'
    volume = Unitwise(value, unit)
    volume.convert_to(UNITWISE_FL_OZ).to_f
  rescue Unitwise::ConversionError => e
    notify_sentry_and_log(e, "Unitwise Conversion Error. #{e.message}", { tags: { product_id: @product.id } })
    nil
  rescue Unitwise::ExpressionError => e
    notify_sentry_and_log(e, "Unitwise Expression Error. #{e.message}", { tags: { product_id: @product.id } })
    nil
  end
end
