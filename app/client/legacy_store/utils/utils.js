jQuery.fn.insertAt = function(index, element) {
  var lastIndex = this.children().size()
  if (index < 0) {
    index = Math.max(0, lastIndex + 1 + index)
  }
  this.append(element)
  if (index < lastIndex) {
    this.children().eq(index).before(this.children().last())
  }
  return this;
};


window.Validation = {
  errorPlacement: function(error, element) {
    var label = $('label[for=\''+$(element).attr('id')+'\']');
    label.hide().after(error);
  },
  highlight: function(element, errorClass, validClass) {
    $(element).addClass(errorClass).removeClass(validClass);
  },
  unhighlight: function(element, errorClass, validClass) {
    var el = $(element),
      label = $('label[for=\''+el.attr('id')+'\']');

    el.removeClass(errorClass).addClass(validClass);
    label.show();
  }
}


var backbone_sync = Backbone.sync, xhrPool = [];

Backbone.sync = function(method, model, options) {
  options = options || {};
  if (method === 'read') {
    if (options.abortPending === true) {
      for (var i = 0; i < xhrPool.length; i++) {
        if (xhrPool[i].readyState > 0 && xhrPool[i].readyState < 4) {
          xhrPool[i].abort();
          xhrPool.splice(i, 1);
        }
      }
    }

    for (var i = 0; i < xhrPool.length; i++) {
      if (xhrPool[i].readyState === 4) {
        xhrPool.splice(i, 1);
      }
    }

    var xhr = backbone_sync(method, model, options);
    xhrPool.push(xhr);
    return xhr;
  } else {
    return backbone_sync(method, model, options);
  }
};

export default {};
