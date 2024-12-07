$(function(){
  var typeSelect = $('#merge_logs_type');
  typeSelect.val(qs('type') || 'products');
  typeSelect.change(function(value) {
    window.location.href = window.location.protocol + '//' + window.location.host + window.location.pathname + '?type=' + $(this).val();
  })
});


function qs(key) {
  key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&"); // escape RegEx meta chars
  var match = location.search.match(new RegExp("[?&]"+key+"=([^&]+)(&|$)"));
  return match && decodeURIComponent(match[1].replace(/\+/g, " "));
}
