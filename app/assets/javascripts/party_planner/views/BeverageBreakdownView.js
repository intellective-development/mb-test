Planner.BeverageBreakdownView = Backbone.View.extend({
  el: '#beverage-breakdown-content',
  successTpl: HandlebarsTemplates['modules/party_planner/beverage_breakdown'],
  loadingTpl: HandlebarsTemplates['modules/party_planner/loading'],
  errorTpl: HandlebarsTemplates['modules/party_planner/error'],

  initialize: function(options){
    Backbone.ModelBinder.SetOptions({
      changeTriggers:{'': 'change', '[contenteditable]': 'blur', '#drink-count': 'keyup'}
    });
    this._modelBinder = new Backbone.ModelBinder();

    this.wine_bottles_view = new Planner.BottleDetailsView({model: Planner.wine_bottles, parent:this}),
    this.liquor_bottles_view = new Planner.BottleDetailsView({model: Planner.liquor_bottles, parent:this}),
    this.beer_bottles_view = new Planner.BottleDetailsView({model: Planner.beer_bottles, parent:this});

    this.bottle_views = [this.wine_bottles_view, this.liquor_bottles_view, this.beer_bottles_view];

    this.model.bind('fetch_loading', _.bind(this.render_loading, this));
    this.model.bind('fetch_error', _.bind(this.render_error, this));
    this.bind('bottles_rendered', _.bind(this.show_bottle_details, this));
  },

  registerFetchSuccessWatcher: function(){ // so that this will happen once everytime nav forward clicked
    //this.model.bind('fetch_success', _.bind(this.render,this));
    this.whenAll(
      [this.model, Planner.wine_bottles, Planner.liquor_bottles, Planner.beer_bottles],
      'fetch_success',
      this.render,
      this
    );
  },

  render: function(){
    var drinks = Planner.drink_data.attributes;

    this.$el.hide();
    this.$el.html(this.successTpl({
      drinks : drinks
    }));

    this.init_sliders();

    this._modelBinder.bind(this.model, this.el);
    this.render_bottle_subviews();


    this.render_bottle_subviews();
    this.hide_excluded_cols();
    _.defer(this.set_column_widths); //must be visible already
    _.defer(this.animate_render, this.$el);
    return this;
  },

  animate_render: function(el){
    el.stop(true).fadeIn({
        duration:400,
        queue:false
      }).css('display','none').slideDown(400);

    $('html, body').animate(
      { scrollTop: $('#beverage-breakdown-content').offset().top+1 },
      800
    );
  },

  render_bottle_subviews: function(){
    this.wine_bottles_view.setElement('#wine-bottle-container');
    this.liquor_bottles_view.setElement('#liquor-bottle-container');
    this.beer_bottles_view.setElement('#beer-bottle-container');

    this.trigger('bottle_elements_set');
  },

  render_loading: function(){
    this.$el.html(this.loadingTpl());
    return this;
  },

  render_error: function(){
    this.$el.html(this.errorTpl());
    return this;
  },

  events: {
    //slide/change events are a part of jquery.nouislider.js package
    'slide #category-slider' : 'set_category_counts',
    'click .view-details' : 'show_bottle_details'
  },

  set_category_counts: function(e){
    var slider   = $('#category-slider'),
        vals     = _.flatten([slider.val()]), //casts to array if not one
        counts   = {wine: 0, liquor: 0, beer: 0},
        excludes = Planner.party_planner.get('excludes');

    if (excludes.length === 0 && vals.length === 2){ // all three present, two input vals
      counts.wine = Math.floor(vals[0]);
      counts.liquor = Math.floor(vals[1] - vals[0]);
      counts.beer = Math.floor(100 - vals[1]);
    }

    else if (excludes.length == 1){ //one missing
      slider.removeClass('all-categories');
      var first_val = Math.floor(vals[0]),
          second_val = 100 - first_val;

      if (excludes.indexOf('wine') > -1){ //if wine present
        counts.liquor = first_val;
        counts.beer = second_val;
      }
      else if (excludes.indexOf('liquor') > -1){ //if wine present
        counts.wine = first_val;
        counts.beer = second_val;
      }
      else{
        counts.wine = first_val;
        counts.liquor = second_val;
      }
    }//if two missing, no input coming in

    this.model.set_percents(counts);
    this.model.set_counts();
  },

  set_slider_colors: function(e){
    var slider   = $('#category-slider'),
        excludes = Planner.party_planner.get('excludes');

    if (excludes.length == 1){ //one missing
      slider.removeClass('all-categories');

      if (excludes.indexOf('wine') > -1){ //if wine present
        slider.addClass('no-wine');
      }
      else if (excludes.indexOf('liquor') > -1){ //if wine present
        slider.addClass('no-liquor');
      }
      else{
        slider.addClass('no-beer');
      }
    }
  },

  show_bottle_details: function(){
    var type_containers = $('.bottle-type-breakdown-container'),
        type_els = this.non_excluded_containers($('.bottle-type-breakdown')),
        type_notes = this.non_excluded_containers($('.bottle-notes'));
    this.match_heights(type_els, type_notes);
    type_containers.show(); // matchHeight() does this, not for singles
    /*type_els.show();
    type_notes.show();
    type_notes.css('opacity','0.0');

    type_containers.slideDown('slow', function(){
      type_notes.fadeTo('slow',1)
    });*/
    $('.view-details').slideUp('slow');
  },

  match_heights: function(type_els, type_notes){
    var max_break_point = 40; //breaks to 1 col at 40em
    if ($(window).width() / parseFloat($('body').css('font-size')) > max_break_point){
      type_els.matchHeight();
      type_notes.matchHeight();
    }
  },

  hide_excluded_cols: function(){
    var excludes = Planner.party_planner.get('excludes');
    if (excludes.indexOf('wine') >= 0){
      $('#wine-container').hide();
      $('.wine-drinks').hide();
    }
    if (excludes.indexOf('liquor') >= 0){
      $('#liquor-container').hide();
      $('.liquor-drinks').hide();
    }
    if (excludes.indexOf('beer') >= 0){
      $('#beer-container').hide();
      $('.beer-drinks').hide();
    }
  },

  non_excluded_containers: function(type_containers){
    var excludes = Planner.party_planner.get('excludes'),
        new_type_containers = [],
        type = '';
    type_containers.each( function(index, value){
      type = $(value).data('type');
      if (excludes.indexOf(type) < 0){
        new_type_containers.push(value);
      }
    });
    return $(new_type_containers);
  },

  set_column_widths: function(){
    var excludes = Planner.party_planner.get('excludes');
    if (excludes.length == 1){
      $('#suggestions-container').addClass('two');
      $('.slider-drinks-container').addClass('two');
    }
    else if (excludes.length == 2){
      $('#suggestions-container').addClass('one');
      $('.slider-drinks-container').addClass('one');
    }
    var add_right_line = function(){
      $('#suggestions-container >:visible:last').addClass('last-visible');
    }
    _.defer(add_right_line); //won't apply properly if still working from previous
  },

  init_sliders: function(){
    var initial_vals = this.model.list_percents().slice(0,2),
        category_slider = $('#category-slider');
    initial_vals[1] += initial_vals[0];

    if (Planner.party_planner.get('excludes').length === 0){ //make a three-way slider
      category_slider.noUiSlider({
        start: [34, 33],
        connect: true,
        step: 1,
        margin: 1,
        range: {
          'min': 0,
          'max': 100
        }
      });
      category_slider.val(initial_vals);
    }

    else if (Planner.party_planner.get('excludes').length === 1){ //two-way
      var initial_vals = this.model.list_percents(),
          initial_val = 0;

      //can only be first or second
      initial_vals[0] === 0 ? initial_val = initial_vals[1] : initial_val = initial_vals[0]

      category_slider.noUiSlider({
        start: 0,
        connect: 'lower',
        step: 1,
        range: {
          'min': 0,
          'max': 100
        }
      });
      category_slider.val(initial_val);
    }

    else{ //otherwise, no slider
      category_slider.hide();
    }
    this.set_slider_colors();

  },

  whenAll: function(objects, event, callback, context){
    var callbackWrapper =  _.after(objects.length, callback);
    context = context || this;
    _.each(objects, function(obj){
      obj.once(event, callbackWrapper, context)
    })
  },



});
