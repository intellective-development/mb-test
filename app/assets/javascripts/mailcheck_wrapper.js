//=require vendor/mailcheck.js

window.mailcheckWrapper = {

  topLevelDomains: ['com', 'net', 'org', 'edu', 'gov', 'info', 'biz', 'mil'],

  initialize: function(inputElement, hintContainer, suggestionString){
    inputElement.on('blur', function() {
      $(this).mailcheck({
        topLevelDomains:  window.mailcheckWrapper.topLevelDomains,       // optional
        suggested: function(element, suggestion) {
          hintContainer.show();
          suggestionString.text(suggestion.full);
          hintContainer.click(function(e){
            e.preventDefault();  //prevent normal link routing functionality
            inputElement.val(suggestion.full);
            hintContainer.hide();
          });
        },
        empty: function(element) {
          hintContainer.hide();
        }
      });
    });
  }
}