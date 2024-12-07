import {
  get,
  head,
  join,
  last,
  split
} from 'lodash-es';
import React from 'react';
import { useLocation } from 'react-router-dom';

import {
  RegionTestimonials as Element
} from './RegionTestimonials';

import content from './content.json';

export const RegionTestimonials = ({ name }) => {
  const location = useLocation();

  let author;
  let review;

  if (location){
    const route = last(split(get(location, 'pathname'), '/'));
    const region = get(content, join(['regions', route], '.'));
    const quotes = head(get(content, join(['reviews', region], '.')));

    author = get(quotes, 'author');
    review = get(quotes, 'review');
  }

  return (
    <Element
      author={author}
      name={name}
      review={review} />
  );
};

export default RegionTestimonials;
