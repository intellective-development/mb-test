const sendForm = (survey, data) => {
  return (
    fetch(`/survey/${survey.token}`, {
      method: 'POST',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': window.csrf_token,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data),
      credentials: 'same-origin'
    })
  );
};

export default sendForm;
