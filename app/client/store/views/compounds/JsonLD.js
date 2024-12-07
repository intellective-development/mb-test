// @flow

import * as React from 'react';

// This is a basic component to render out json-ld data for SEO purposes.
// We render it out as a standard React element to make server rendering easier and to make sure we're not rendering duplicates,
// but in the future we may want to consider using portals or something to keep the script tags out of the middle of the DOM.
// See schema.org for more info on the shapes of data that may be passed.

// TODO: ensure this fully supports for server side rendering.

type JsonLDProps = {data: Object};
const JsonLD = ({data}: JsonLDProps) => {
  return (
    <script
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(data)
      }}
      type="application/ld+json" />
  );
};

export default JsonLD;
