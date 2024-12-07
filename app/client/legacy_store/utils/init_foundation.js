function initFoundation(){
  $(document).foundation(); //re-inits foundation, currently just lets hitting escape work
  $(document).foundation().foundation('reveal', {
    'animation' : 'fadeAndPop',
    'animationSpeed' : 0,
  });
}

export default initFoundation;
