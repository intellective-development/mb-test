import mailcheck from 'mailcheck';
const topLevelDomains = ['com', 'net', 'org', 'edu', 'gov', 'info', 'biz', 'mil'];

const mailcheckWrapper = {
  initialize: function(inputElement, hintContainer, suggestionString){
    inputElement.on('blur', function() {
      mailcheck.run({
        email: inputElement[0].value,
        topLevelDomains:  topLevelDomains,
        suggested: function(suggestion) {
          hintContainer.show();
          suggestionString.text(suggestion.full);
          hintContainer.click(function(e){
            e.preventDefault();  //prevent normal link routing
            inputElement.val(suggestion.full);
            hintContainer.hide();
          });
        },
        empty: function() {
          hintContainer.hide();
        }
      });
    });
  }
};

export default mailcheckWrapper;
