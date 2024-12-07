Planner.PartyParametersView = Backbone.View.extend({
  el: '#party-params-content',
  party_plannerTpl: HandlebarsTemplates['modules/party_planner/party_params'],

  initialize: function(options){
    this._modelBinder = new Backbone.ModelBinder();
  },

  render: function(){
    this.$el.html(this.party_plannerTpl({
      party_planner : Planner.party_planner.attributes
    }));

    this._modelBinder.bind(this.model, this.el);
    return this;
  },

  events: {
    'keyup #people' : 'correct_people_width',
    'click #people' : 'empty_val',
    'blur #people' : 'check_blank',

    'click .tod-options li': 'choose_tod',
    'click .duration-options li': 'choose_duration',
    'click': 'remove_selects',

    'mouseover .dropdown li':'active_arrow',
    'mouseout .dropdown li':'active_arrow',

    'click #no_liquor': 'strikeout',
    'click #no_wine': 'strikeout',
    'click #no_beer': 'strikeout'
  },

  remove_selects: function(e){
    var el = $(e.target);
    $('.dropdown > li.selected').removeClass('selected');
    this.sync_arrow_color($('.dropdown')); //disapear it on dropdown

    if (el.hasClass('duration')){
      $('.tod-options').removeClass('active');
      this.launch_duration_select(el);
    }
    else if (el.hasClass('time-of-day')){
      $('.duration-options').removeClass('active');
      this.launch_tod_select(el);
    }
    else{
      $('.dropdown').removeClass('active');
    }
  },

  empty_val: function(e){
    $(e.currentTarget).val('');
    this.adjust_field_width($(e.currentTarget));
  },

  check_blank: function(e){
    var el = $(e.target);
    if (el.val()===''){
      this.model.set('people',0);
      el.val(0); //just in case, so repeated 0's still update it
    }
    this.adjust_field_width(el);
  },

  launch_tod_select: function(el){
    this.launch_select($('.tod-options'), this.model.get('time_of_day'), el);
  },

  launch_duration_select: function(el){
    this.launch_select($('.duration-options'), this.model.get('duration'), el);
  },

  launch_select: function(dropdown, model_val, el){
    var opts = dropdown.children('li');

    for(var i=0; i < opts.length; i++){
      var opt = opts.eq(i);
      if (opt.text() === model_val){
        opt.addClass('selected');
      }
    }
    this.sync_arrow_color(dropdown);
    this.center_on_other(dropdown, el);
    dropdown.toggleClass('active');
  },


  sync_arrow_color: function(dropdown){ //so the arrow and the middle elements are the same color
    var mid = dropdown.children('.mid'),
        arrow = dropdown.children('.after-arrow'),
        color = '';
    if (mid !== undefined && arrow !== undefined){
      color = mid.css('background-color');
      dropdown.children('.after-arrow').css('border-top-color',color);
    }
  },

  choose_tod: function(e){
    var val = $(e.currentTarget).text();
    this.model.set('time_of_day', val);
  },

  choose_duration: function(e){
    var el = $(e.currentTarget);
    this.model.set('duration', el.text());
  },

  active_arrow: function(e){
    var dropdown = $(e.target).parent();
    this.sync_arrow_color(dropdown);
  },

  strikeout: function(e){
    var el = $(e.currentTarget),
        name = el.data('name');

    el.toggleClass('strikeout');
    Planner.party_planner.add_to_excludes(name);
  },


  correct_people_width: function(e){
    var el = $(e.currentTarget);
    this.adjust_field_width(el);
  },

  adjust_field_width: function(el){
    //var oneLetterWidth = 23;
    var font_size = parseFloat(el.css('font-size')),
        oneLetterWidth = font_size - font_size/3,
        len = el.val().length;
    el.width(len * oneLetterWidth);
  },

  center_on_other: function(to_center, center_on){
    var on_position = center_on.offset();
    on_position.top -= to_center.height() + 5;
    on_position.left += to_center.width()/-2 + center_on.outerWidth()/2;
    to_center.offset(on_position);
  },


});
