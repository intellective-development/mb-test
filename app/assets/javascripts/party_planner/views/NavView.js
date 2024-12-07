Planner.NavView = Backbone.View.extend({
  el: '#party-planner-nav',
  party_plannerTpl: HandlebarsTemplates['modules/party_planner/nav'],

  initialize: function(options){
    this.parent = options.parent;
  },

  render: function(){
    this.$el.html(this.party_plannerTpl({
    }));
    return this;
  },

  events: {
    'click #back' : 'back',
    'click #forward' : 'forward'
  },

  back: function(e){
    this.parent.trigger('page_back');
  },

  forward: function(e){
    this.parent.trigger('page_forward');
  },

});