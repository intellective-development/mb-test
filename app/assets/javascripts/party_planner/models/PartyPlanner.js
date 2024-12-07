Planner.PartyPlanner = Backbone.Model.extend({
  url: '/', //should be no url

  defaults: {
    duration: 1,
    time_of_day: 'day',
    people: 50,
  },

  initialize: function(){
    this.set('excludes', []);
  },

  add_to_excludes: function(num){
    //acts as a toggle, basically
    var excludes = this.get('excludes'),
        index = $.inArray(num, excludes);

    if (index > -1){ //if present, remove
      excludes.splice(index, 1);
    } else{ //otherwise, add
      excludes.push(num);
    }
    this.set('excludes', excludes);
  }
});
