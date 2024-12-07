const post = (url, data) => (
  $.ajax({
    url: url,
    type: 'POST',
    data: data,
    beforeSend(xhr){
      xhr.setRequestHeader('X-CSRF-Token', Data.csrf_token);
    }
  })
);

export default post;
