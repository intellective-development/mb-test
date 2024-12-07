Planner.BottleData = Backbone.Model.extend({
  defaults: {
    type: '',
    bottles:0
  },
  urlRoot: '/api/party_planner/',

  initialize: function(options){
    this.set('type', options.type);
    this.set('excludes', []);
  },

  url:function(){
    return this.urlRoot + this.get('type') + '_bottle_count';
  },

  call_api: function(){
    var model = this;
    model.trigger('fetch_loading');
    this.fetch({
      data: {
        drinks: Planner.drink_data.get(model.get('type')),
        time_of_day: Planner.party_planner.get('time_of_day'),
        guests: Planner.party_planner.get('people'),
        exclude_types: model.get('excludes')
      },
      success: function(){
        model.set('bottles', model.format_count(model.get('bottles')));
        model.save_types();
        model.save_cases();
        var trigger = function(){model.trigger('fetch_success');}
        _.defer(trigger);
      },
      error: function(){
        model.trigger('fetch_error');
      }
    });
  },

  save_types: function(){
    var model = this,
        types = this.get('types');

    jQuery.each(types, function(type, type_data){
      model.set(type+'_name', type);
      model.set(type+'_count', model.format_count(type_data.count));
      //model.set(type+'_id', type_data.id);
    });
  },

  save_cases: function(){
    var cases = this.get('cases'),
        case_string = '';
    if (!$.isEmptyObject(cases)){
      case_string = this.format_count(cases.count);
      cases.count == '1' ? case_string += ' case' : case_string += ' cases'
      cases.extra_bottles !== 0 ? case_string += ' + ' + cases.extra_bottles : case_string = case_string
      this.set('case_counts', case_string);
      this.set('case_size', cases.size + ' bottles per case')
    }
    else{
      this.set('case_counts', undefined);
      this.set('case_counts', undefined);
    }
  },

  add_to_excludes: function(num){
    //acts as a toggle, basically
    var excludes = this.get('excludes'),
        index = $.inArray(num, excludes);

    if (index > -1){ //if present, remove
      excludes.splice(index, 1);
    }else{ //otherwise, add
      excludes.push(num);
    }
    this.set('excludes', excludes);
  },

  format_count: function(counter){
    return counter.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  },

});
