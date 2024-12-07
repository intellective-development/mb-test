Planner.BottleDetailsView = Backbone.View.extend({

  successTpl: HandlebarsTemplates['modules/party_planner/bottle_simple'],
  loadingTpl: HandlebarsTemplates['modules/party_planner/loading'],
  errorTpl: HandlebarsTemplates['modules/party_planner/error'],

  detailTpl: HandlebarsTemplates['modules/party_planner/bottle_detailed'],
  bottleTypeTpl: HandlebarsTemplates['modules/party_planner/bottle_type_data'],
  bottleNotesTpl: HandlebarsTemplates['modules/party_planner/bottle_notes'],


  initialize: function(options){
    this.parent = options.parent;
    this.listenTo(this.parent, 'bottle_elements_set', this.simple_render);

    this._modelBinder = new Backbone.ModelBinder();
    this.parent = options.parent;

    this.listenTo(this.parent, 'bottle_elements_set', this.render);
  },

  render: function(){
    this.$el.html(this.successTpl({
      type: this.model.get('type'),
      notes: this.model.get('notes')
    }));
    //$('.bottle-type-breakdown-container').hide();
    this.delegateEvents(this.events);

    var view = this,
        type_html = '',
        el = this.$el.find('.bottle-type-breakdown'),
        types = this.model.get('types');

    $.each(types, function(type, data){
      type_html += view.bottleTypeTpl({
        type: type,
        type_count: data.count,
        id: data.id,
        subtypes: data.subtypes
      });
    });
    el.html(type_html);
    this.display_excludes_as_excluded();

    var view = this;
    var bind_it = function(){
      view._modelBinder.bind(view.model, view.$el);
      view.parent.trigger('bottles_rendered');
    };
    _.defer(bind_it);
    return this;
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
   'click .subtype-container' : 'exclude_type',
   'click #cases' : 'toggle_case'
  },

  /*render_details: function(e){
    /*
    this.delegateEvents(this.events);

    var view = this,
        type_html = '',
        el = this.$el.find('.bottle-type-breakdown'),
        types = this.model.get('types');

    $.each(types, function(type, data){
      type_html += view.bottleTypeTpl({
        type: type,
        type_count: data.count,
        id: data.id,
        subtypes: data.subtypes
      });
    });
    el.html(type_html);
    this.display_excludes_as_excluded();
    this._modelBinder.bind(this.model, this.$el);
    //this.parent.trigger('category_updated');

  },
*/
  exclude_type: function(e){
    var el = $(e.currentTarget),
        id = el.data('type-id');

    el.toggleClass('excluded');
    this.model.add_to_excludes(id);
    this.model.call_api();
  },

  toggle_case: function(e){
    var el = $(e.target).parent('#cases');
    el.children('span').toggleClass('hidden');
  },

  display_excludes_as_excluded: function(){
    var excludes = this.model.get('excludes'),
        type = '';
    this.$el.find('.subtype-container').each(function(index, el){
      type = $(el).data('type-id');
      if (excludes.indexOf(type) >= 0){ //if it's on the exclude list
        $(el).addClass('excluded');
      }
    });
  }

});
