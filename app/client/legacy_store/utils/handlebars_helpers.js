import _ from 'lodash';
import moment from 'moment';
import Handlebars from 'handlebars-template-loader/runtime';

Handlebars.registerHelper('cart_total_row', function() {
  return new Handlebars.SafeString('$' + (this.attributes.quantity * this.attributes.product.attributes.price).toFixed(2));
});

Handlebars.registerHelper('slugify', function(context, options) {
  return new Handlebars.SafeString(_.kebabCase(context));
});

Handlebars.registerHelper('selected', function(context, options) {
  return context ? 'selected' : '';
});

Handlebars.registerHelper('if_eq_slug', function(context, options) { // LD: DEPRECATED
  if (_.kebabCase(context) == options.hash.compare)
    return options.fn(this);
  return options.inverse(this);
});

Handlebars.registerHelper('times', function(n, block) {
  var accum = '';
  for(var i = 0; i < n; ++i)
    accum += block.fn(i);
  return accum;
});

Handlebars.registerHelper('increment', function(n, options){
  return parseInt(n) + 1;
});

Handlebars.registerHelper('selected', function(option, value){
  return option === value ? 'selected' : '';
});

Handlebars.registerHelper('json', function(obj) {
  if (_.isObject(obj)){ //if not a primitive
    return JSON.stringify(obj);
  }
  return obj;
});

Handlebars.registerHelper('titleize', function(obj) {
  return _.startCase(obj);
});

Handlebars.registerHelper('parameterize', function(obj) { // LD: DEPRECATED
  obj = obj || '';
  return _.trim(obj.replace(/\W+/g, '-'), '-').toLowerCase();
});

Handlebars.registerHelper('options_selected', function(value) {
  var ret = '',
      found_selected = false;
  for (var i = 1; i < 21; i++) {
      var option = '<option value="' + i +'"';
      if (value == i) {
          found_selected = true;
          option += ' selected="selected"';
      }
      option += '>'+ Handlebars.Utils.escapeExpression(i) + '</option>';
      ret += option;
  }
  if (!found_selected){
    ret += '<option value="' + value + '" selected="selected">' + Handlebars.Utils.escapeExpression(value) + '</option>';
  }
  return new Handlebars.SafeString(ret);
})

// Checkout Helpers

Handlebars.registerHelper('format_price_free', function(price, options){
  options = options || {};
  if (price == null)
    return '$';
  else if (parseFloat(price) === 0)
    return 'FREE';
  else
    return '$' + parseFloat(price).toFixed(2);
});

Handlebars.registerHelper('equal', function(lvalue, rvalue, options) {
  if (arguments.length < 3)
    throw new Error('Handlebars Helper equal needs 2 parameters');
  if( lvalue!=rvalue ) {
    return options.inverse(this);
  } else {
    return options.fn(this);
  }
});

Handlebars.registerHelper('or', function(lvalue, rvalue, options) {
  if (arguments.length < 2)
    throw new Error('Handlebars Helper equal needs 2 parameters');
  return lvalue || rvalue;
});

Handlebars.registerHelper('underscored', function(str){
  return (_.snakeCase(str));
});

Handlebars.registerHelper('math', function(lvalue, operator, rvalue, options) {
    lvalue = parseFloat(lvalue);
    rvalue = parseFloat(rvalue);

    return {
        '+': lvalue + rvalue,
        '-': lvalue - rvalue,
        '*': lvalue * rvalue,
        '/': lvalue / rvalue,
        '%': lvalue % rvalue
    }[operator];
});

export default {};
