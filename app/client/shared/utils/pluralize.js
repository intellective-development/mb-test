const pluralize = (base_word, count, plural_override = null) => {
  const plural_word = plural_override || `${base_word}s`;
  return count === 1 ? base_word : plural_word;
};

export default pluralize;
