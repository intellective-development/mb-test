/*!
 * jQuery Validation Plugin v1.12.0
 *
 * http://jqueryvalidation.org/
 *
 * Copyright (c) 2014 Jörn Zaefferer
 * Released under the MIT license
 */
(function() {

  function stripHtml(value) {
    // remove html tags and space chars
    return value.replace(/<.[^<>]*?>/g, " ").replace(/&nbsp;|&#160;/gi, " ")
    // remove punctuation
    .replace(/[.(),;:!?%#$'\"_+=\/\-“”’]*/g, "");
  }

  jQuery.validator.addMethod("maxWords", function(value, element, params) {
    return this.optional(element) || stripHtml(value).match(/\b\w+\b/g).length <= params;
  }, jQuery.validator.format("Please enter {0} words or less."));

  jQuery.validator.addMethod("minWords", function(value, element, params) {
    return this.optional(element) || stripHtml(value).match(/\b\w+\b/g).length >= params;
  }, jQuery.validator.format("Please enter at least {0} words."));

  jQuery.validator.addMethod("rangeWords", function(value, element, params) {
    var valueStripped = stripHtml(value),
      regex = /\b\w+\b/g;
    return this.optional(element) || valueStripped.match(regex).length >= params[0] && valueStripped.match(regex).length <= params[1];
  }, jQuery.validator.format("Please enter between {0} and {1} words."));

}());

// Accept a value from a file input based on a required mimetype
jQuery.validator.addMethod("accept", function(value, element, param) {
  // Split mime on commas in case we have multiple types we can accept
  var typeParam = typeof param === "string" ? param.replace(/\s/g, "").replace(/,/g, "|") : "image/*",
  optionalValue = this.optional(element),
  i, file;

  // Element is optional
  if (optionalValue) {
    return optionalValue;
  }

  if (jQuery(element).attr("type") === "file") {
    // If we are using a wildcard, make it regex friendly
    typeParam = typeParam.replace(/\*/g, ".*");

    // Check if the element has a FileList before checking each file
    if (element.files && element.files.length) {
      for (i = 0; i < element.files.length; i++) {
        file = element.files[i];

        // Grab the mimetype from the loaded file, verify it matches
        if (!file.type.match(new RegExp( ".?(" + typeParam + ")$", "i"))) {
          return false;
        }
      }
    }
  }

  // Either return true because we've validated each file, or because the
  // browser does not support element.files and the FileList feature
  return true;
}, jQuery.validator.format("Please enter a value with a valid mimetype."));

jQuery.validator.addMethod("alphanumeric", function(value, element) {
  return this.optional(element) || /^\w+$/i.test(value);
}, "Letters, numbers, and underscores only please");

jQuery.validator.addMethod("integer", function(value, element) {
  return this.optional(element) || /^-?\d+$/.test(value);
}, "A positive or negative non-decimal number please");

jQuery.validator.addMethod("lettersonly", function(value, element) {
  return this.optional(element) || /^[a-z]+$/i.test(value);
}, "Letters only please");

jQuery.validator.addMethod("letterswithbasicpunc", function(value, element) {
  return this.optional(element) || /^[a-z\-.,()'"\s]+$/i.test(value);
}, "Letters or punctuation only please");

jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
  phone_number = phone_number.replace(/\s+/g, "");
  return this.optional(element) || phone_number.length > 9 &&
    phone_number.match(/^(\+?1-?)?(\([2-9]([02-9]\d|1[02-9])\)|[2-9]([02-9]\d|1[02-9]))-?[2-9]([02-9]\d|1[02-9])-?\d{4}$/);
}, "Please specify a valid phone number");

jQuery.validator.addMethod("zipcodeUS", function(value, element) {
  return this.optional(element) || /^\d{5}-\d{4}$|^\d{5}$/.test(value);
}, "The specified US ZIP Code is invalid");
