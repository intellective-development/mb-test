// @flow
import * as React from 'react';
import _ from 'lodash';

import * as MBText from './MBText';

type Match = { offset: number, length: number };

type Props = {
  children: string,
  className?: stringl,
  match_classname: string,
  matches: Match[]
}

// TODO this should probably use MBText for formatting, once we embellish MBText a bit more
const wrapSubstringMatches = (str: string, matches: Match[], match_classname: string) => {
  let tail = 0;
  const interpolated = matches && matches.reduce((prev_acc, match, index) => {
    const maybe_gap = tail !== match.offset && <MBText.Span key={`${index}prev`}>{str.slice(tail, match.offset)}</MBText.Span>;
    const wrapped_match = (
      <MBText.Span key={`${index}match`} className={match_classname}>
        {str.slice(match.offset, match.offset + match.length)}
      </MBText.Span>
    );
    const acc = [...prev_acc, maybe_gap, wrapped_match];
    tail = match.offset + match.length;
    return acc;
  }, []);
  const maybe_final_tail = tail < str.length && <MBText.Span key="tail">{str.slice(tail)}</MBText.Span>;
  return [interpolated, maybe_final_tail];
};

export const makeMatches = (input_str: string, match_str: string) => {
  const matches: Match[] = [];

  if (_.isEmpty(input_str) || _.isEmpty(match_str)){
    return matches;
  }

  const re = new RegExp(match_str, 'gi');
  let match = re.exec(input_str);

  while (match != null){
    matches.push({ offset: match.index, length: match_str.length });
    match = re.exec(input_str);
  }

  return matches;
};

const MBTextWithMatches = ({ children, matches, className, match_classname }: Props) => (
  <MBText.Span className={className}>
    {children && wrapSubstringMatches(children, matches, match_classname)}
  </MBText.Span>
);

export default MBTextWithMatches;
