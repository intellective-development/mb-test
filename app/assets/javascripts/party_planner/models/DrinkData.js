Planner.DrinkData = Backbone.Model.extend({
  defaults: {
    drinks: 0,
    wine: 0,
    liquor: 0,
    beer: 0,
    wine_percent: 0,
    liquor_percent: 0,
    beer_percent: 0,
    timer: 0
  },
  urlRoot: '/api/party_planner/drink_count',

  initialize: function(){
    this.bind('change:drinks', this.set_counts, this);

    var update_wine_throttled = _.throttle(this.update_wine_bottles, 500);
    var update_liquor_throttled = _.throttle(this.update_liquor_bottles, 500);
    var update_beer_throttled = _.throttle(this.update_beer_bottles, 500);

    this.bind('change:wine', update_wine_throttled, this);
    this.bind('change:liquor', update_liquor_throttled, this);
    this.bind('change:beer', update_beer_throttled, this);
  },

  call_api: function(){
    var model = this;
    model.trigger('fetch_loading');
    Planner.drink_data.fetch({
      data: { num_people: Planner.party_planner.get('people'),
              duration: Planner.party_planner.get('duration'),
              time_of_day: Planner.party_planner.get('time_of_day'),
              exclude_types: Planner.party_planner.get('excludes')
            },
      silent: true,

      success: function(){
        model.set_drink_counts();
        model.set_initial_percents();
        model.set_recommended_drinks();
        model.set_counts();
        model.trigger('fetch_success');
      },
      error: function(){
        model.trigger('fetch_error');
      }
    });
  },

  set_counts: function(){
    var drinks = this.attributes,
        wine_count = this.percentage(drinks.wine_percent, drinks.drinks),
        liquor_count = this.percentage(drinks.liquor_percent, drinks.drinks),
        beer_count = this.percentage(drinks.beer_percent, drinks.drinks);

    this.set('wine', wine_count);
    this.set('liquor', liquor_count);
    this.set('beer', beer_count);
    this.format_drink_counts();
  },


  set_initial_percents: function(){
    var drinks = this.attributes,
        drink_count = drinks.wine + drinks.liquor + drinks.beer;
    this.set('drinks', drink_count);
    this.set('wine_percent', this.percent(drinks.wine, drink_count) );
    this.set('liquor_percent', this.percent(drinks.liquor, drink_count) );
    this.set('beer_percent', this.percent(drinks.beer,  drink_count) );
  },

  set_percents: function(percents){
    Planner.drink_data.set('wine_percent', percents.wine);
    Planner.drink_data.set('liquor_percent', percents.liquor);
    Planner.drink_data.set('beer_percent', percents.beer);
  },

  set_drink_counts: function(){
    var drinks = this.attributes;
    this.set('wine', drinks.wine.count);
    this.set('liquor', drinks.liquor.count);
    this.set('beer', drinks.beer.count);
  },

  format_drink_counts: function(){
    var drinks = this.attributes;
    this.set('drinks_string', this.format_count(drinks.drinks));
    this.set('wine_count_string', this.format_count(drinks.wine));
    this.set('liquor_count_string', this.format_count(drinks.liquor));
    this.set('beer_count_string', this.format_count(drinks.beer));
  },

  set_recommended_drinks: function(){
    this.set('recommended_drinks', this.get('drinks'));
    this.set('recommended_drinks_string', this.format_count(this.get('drinks')));
  },

  update_wine_bottles: function(){
    Planner.wine_bottles.call_api();
  },
  update_liquor_bottles: function(){
    Planner.liquor_bottles.call_api();
  },
  update_beer_bottles: function(){
    Planner.beer_bottles.call_api();
  },

  list_percents: function(){
    return [this.get('wine_percent'), this.get('liquor_percent'), this.get('beer_percent')];
  },

  percent: function(num, den){ //gets the percent from a ratio
    return Math.round((num/den)*100) || 0;
  },

  percentage: function(percent, total){ //gets the portion of a whole
    return Math.round(total*(percent/100) ) || 0;
  },

  format_count: function(num){
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','); //adds commas
  },

});
