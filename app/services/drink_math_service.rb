class DrinkMathService
  # rubocop:disable Style/MutableConstant
  # DEFAULT DRINK/BOTTLE RATIOS
  CATEGORY_RATIO    = { wine: 0.65, liquor: 0.20, beer: 0.15 }
  WINE_DAY_RATIO    = { white: 0.5, red: 0.214, champagne: 0.142, rose: 0.142 }
  WINE_NIGHT_RATIO  = { white: 0.3, red: 0.514, champagne: 0.142, rose: 0.142 }
  LIQUOR_RATIO      = { vodka: 0.357, whiskey: 0.286, gin: 0.214, rum: 0.071, tequila: 0.071 }
  BEER_RATIO        = { domestic: 0.75, imported: 0.25 }

  DRINKS_PER_BOTTLE = {
    liquor: 22,
    wine: 5,
    champagne: 5,
    beer: 1
  }
  AMOUNT_PER_PACKAGE = {
    beer: 6, # six pack
    ice: 5 # 5lb bags
  }
  MIXER_DRINK_RATIO = 3

  TIME_OF_DAY_SCALE = { afternoon: 1, evening: 1.07, night: 1.15 }
  # rubocop:enable Style/MutableConstant

  # how many drinks will be needed
  def self.drink_count(num_people, duration, time_of_day, exclude_types = [])
    num_drinks = (duration + 1) * num_people # base
    num_drinks = (num_drinks * time_of_day_scaler(time_of_day)).ceil # scale by t_o_d

    drink_ratios = CATEGORY_RATIO.dup
    exclude_from_ratio(drink_ratios, exclude_types)

    drinks = {}
    drinks[:wine] = (num_drinks * drink_ratios[:wine]).ceil
    drinks[:liquor] = (num_drinks * drink_ratios[:liquor]).ceil
    drinks[:beer] = (num_drinks * drink_ratios[:beer]).ceil
    count = drinks.values.inject(:+) # the real total is once you've added them all together

    drinks = add_id_data(drinks)
    drinks[:count] = count
    drinks
  end

  def self.liquor(num_drinks)
    divide_round_up(num_drinks, DRINKS_PER_BOTTLE[:liquor]) # 22 drinks per bottle
  end

  def self.wine(num_drinks)
    divide_round_up(num_drinks, DRINKS_PER_BOTTLE[:wine]) # 5 drinks per bottle
  end

  def self.beer(num_drinks)
    bottles = divide_round_up(num_drinks, DRINKS_PER_BOTTLE[:beer]) # 1 drink per bottle
    divide_round_up(bottles, AMOUNT_PER_PACKAGE[:beer]) * AMOUNT_PER_PACKAGE[:beer] # multiples of 6
  end

  def self.champagne_toast(num_guests)
    divide_round_up(num_guests, DRINKS_PER_BOTTLE[:champagne]) # 5 drinks per bottle
  end

  def self.mixer(num_drinks) # num_drinks = number of liquor drinks
    liquor_liters = liquor(num_drinks) # assuming liquor bottles are 1L, bottles = liters
    liquor_liters * MIXER_DRINK_RATIO
  end

  def self.ice(drinks) # num_drinks = number of liquor drinks
    lbs = divide_round_up(drinks, 2)
    (lbs / AMOUNT_PER_PACKAGE[:ice]).ceil * AMOUNT_PER_PACKAGE[:ice] # round up to nearest 5
  end

  # ----- BOTTLE DATA ----- #
  def self.wine_types(num_bottles, time_of_day = 'day', exclude_types = [])
    bottle_ratios = time_of_day == 'day' ? WINE_DAY_RATIO.dup : WINE_NIGHT_RATIO.dup
    bottles = get_type_data(bottle_ratios, num_bottles, exclude_types)

    bottles[:white][:subtypes] = 'Chardonnay & Sauvignon Blanc'
    bottles[:red][:subtypes] = 'Pinot Noir & Cabernet Sauvignon'
    bottles
  end

  def self.liquor_types(num_bottles, exclude_types = [])
    bottle_ratios = LIQUOR_RATIO.dup
    bottles = get_type_data(bottle_ratios, num_bottles, exclude_types)

    bottles[:whiskey][:subtypes] = 'Bourbon & Scotch'
    bottles[:rum][:subtypes] = 'Dark & Light'
    bottles
  end

  def self.beer_types(num_bottles, exclude_types = [])
    bottle_ratios = BEER_RATIO.dup
    bottles = get_type_data(bottle_ratios, num_bottles, exclude_types)

    # HACK: to get the two to be powers of 6 (for 6 packs)
    imported_remainder = bottles[:imported][:count] % 6
    if imported_remainder.nonzero?
      bottles[:domestic][:count] += imported_remainder
      bottles[:imported][:count] -= imported_remainder
    end
    bottles
  end

  #----- CASE DATA -----#
  def self.get_case_counts(case_size, bottle_count)
    counts = {}
    counts[:size] = case_size
    counts[:count] = bottle_count / case_size
    counts[:extra_bottles] = bottle_count % case_size
    counts = {} if counts[:count] < 4
    counts
  end

  #----- NOTE DATA -----#
  def self.get_notes(type, options)
    I18n.t("party_planner.#{type}", options)
  end

  #--- bottle type helpers ---#
  def self.get_type_data(bottle_ratios, num_bottles, exclude_types) # orchestrates bottle type hash creation
    bottle_ratios = exclude_from_ratio(bottle_ratios, exclude_types) if exclude_types.present?
    bottle_counts = initial_bottles(bottle_ratios, num_bottles)

    all_excluded = bottle_ratios.count <= exclude_types.to_a.size
    bottle_counts = adjust_bottle_vals(bottle_counts, num_bottles, bottle_ratios) unless all_excluded

    add_id_data(bottle_counts)
  end

  def self.initial_bottles(bottle_ratios, num_bottles)
    bottles = {}
    bottle_ratios.each do |type, weight|
      bottles[type] = (num_bottles * weight).round
    end
    bottles
  end

  def self.adjust_bottle_vals(bottles, num_bottles, bottle_ratios)
    # drinks, we round up to bottles. bottles, we make it work, trying to stick to weights
    # these are usually off by less than 1% anyways, so this has a minor impact on ratio
    bottle_sum = bottles.values.inject(:+)
    index = bottles.length - 1
    while bottle_sum > num_bottles
      type = bottles.keys[index]
      if (bottles[type]).nonzero? # don't let it get negative
        bottles[type] -= 1
        bottle_sum -= 1 # should redo the bottle_sum, but it's expensive
      end
      index.zero? ? index = bottles.length - 1 : index -= 1
    end

    index = 0
    while bottle_sum < num_bottles
      type = bottles.keys[index]
      if bottle_ratios[type] != 0.0 # don't add to it if its been zeroed out, for exclusion
        bottles[type] += 1
        bottle_sum += 1
      end
      index == bottles.length - 1 ? index = 0 : index += 1
    end
    # trim_zero_vals(bottles)
    bottles
  end

  def self.add_id_data(bottle_counts)
    bottles = {}
    bottle_counts.each do |name, count|
      ProductType.find_by(name: name.to_s).id
      bottles[name] = { count: count }
      # bottles[name] = { count: count, id: type_id }
    end
    bottles
  end

  #--- drink logic ---#
  def self.time_of_day_scaler(time_of_day)
    hours = TIME_OF_DAY_SCALE
    hours[time_of_day.to_sym] ||= 1
  end

  #--- ratio logic --#
  def self.exclude_from_ratio(drink_ratios, exclude_types)
    exclude_types ||= []
    exclude_types.each do |type_id|
      drink_ratios = shift_ratios(drink_ratios, type_id.to_sym)
    end
    drink_ratios
  end

  def self.shift_ratios(drink_ratios, remove)
    # remove the removed one, get the new total. So the remaining vals can know their ratio of the remaining
    new_total = (drink_ratios.values.inject(:+) - drink_ratios[remove]).nonzero? || 1 # if both zero, 1 doesn't matter

    drink_ratios.each do |drink, ratio|
      drink_ratios[drink] = ratio / new_total
    end
    drink_ratios[remove] = 0.0
    drink_ratios
  end

  #--- do some math ---#
  def self.divide_round_up(divided, divisor) # divided = drinks, divisor = drinks_per_bottle
    (divided + divisor - 1) / divisor
  end

  def self.trim_zero_vals(hash)
    hash.each do |k, v|
      hash.delete(k) if v.zero?
    end
    hash
  end
end
