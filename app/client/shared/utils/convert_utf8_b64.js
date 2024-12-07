export function utf8ToB64(str){
  //less of a concern, because most things are valid utf8
  return window.btoa(unescape(encodeURIComponent(str)));
}

export function b64ToUtf8(str){
  let atob_string;
  try {
    atob_string = decodeURIComponent(escape(window.atob(str)));
  } catch (e){
    // if the window.atob fails because the string is not correctly encoded
    if (e instanceof DOMException){
      atob_string = null;
    } else {
      throw e;
    }
  }
  return atob_string;
}

export const encodeObject = function(object){
  return utf8ToB64(JSON.stringify(object));
};

export const decodeObject = function(encoded_object){
  return JSON.parse(b64ToUtf8(encoded_object));
};
