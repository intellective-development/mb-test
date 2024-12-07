Planner.PlannerView = Backbone.View.extend({
  el: '#party-planner',
  party_plannerTpl: HandlebarsTemplates['modules/party_planner/planner'],

  initialize: function(options){
    Planner.party_planner = new Planner.PartyPlanner();
    Planner.drink_data = new Planner.DrinkData();

    Planner.wine_bottles = new Planner.BottleData({type:'wine'});
    Planner.liquor_bottles = new Planner.BottleData({type:'liquor'});
    Planner.beer_bottles = new Planner.BottleData({type:'beer'});
    Planner.wine_bottles.set('excludes', ['rose', 'champagne'])

    this.render();

    var params = new Planner.PartyParametersView({model: Planner.party_planner}),
        beverage = new Planner.BeverageBreakdownView({model: Planner.drink_data});

    this.subviews = [ params, beverage ];
    this.subview_index = 0;

    this.subviews[this.subview_index].render();

    this.navView = new Planner.NavView({parent:this});
    this.navView.render();

    this.on('page_forward', this.forward);
    this.on('page_back', this.back);
  },

  render: function(){
    this.$el.html(this.party_plannerTpl());
    return this;
  },

  forward: function(){
    if (Planner.party_planner.get('people') === 0){
      var message_container = $('#error-message-container');
      message_container.text('Please invite some guests.');
      message_container.fadeTo('slow',1).delay(1000).fadeTo('slow',0);
    }
    else if (Planner.party_planner.get('excludes').length === 3){
      var message_container = $('#error-message-container');
      message_container.text('Please select at least one drink option.');
      message_container.fadeTo('slow',1).delay(1000).fadeTo('slow',0);
    }
    else{
      this.subviews[1].registerFetchSuccessWatcher();
      this.subviews[1].model.call_api(); //fetch, renders will occur naturally
      $('.planner-nav#forward').text('Update');
    }
  }
});
