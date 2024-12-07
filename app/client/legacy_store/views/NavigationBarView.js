import * as React from 'react';
import _ from 'lodash';
import ReactDOM from 'react-dom';
import renderComponentRoot from 'shared/utils/render_component_root';

import Navigation from '../../store/views/compounds/Navigation';

const renderNavigation = () => renderComponentRoot(React.createElement(Navigation, {}), document.getElementById('site-header'));

Store.NavigationBarView = Backbone.View.extend({
  initialize: function(options){
    this.render();
  },
  hideNavigation: function(){
    $('#layout').addClass('dark-bg');
    $('.links', this.$footer).hide();
    $('.help', this.$footer).show();
    $('#header-strip').hide();
  },
  showNavigation: function(){
    $('#layout').removeClass('dark-bg');
    $('.links', this.$footer).show();
    $('.help', this.$footer).hide();
    $('#header-strip').show();
  },
  render: function(){
    renderNavigation();
  }
});

// enable hot reloading
if (module.hot) module.hot.accept('../../store/views/compounds/Navigation', renderNavigation);

export default Store.NavigationBarView;

//TODO: remove! use real dependencies!
window.Store.NavigationBarView = Store.NavigationBarView;
