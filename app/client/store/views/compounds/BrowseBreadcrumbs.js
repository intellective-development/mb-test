// @flow

import * as React from 'react';

import { MBLink, MBText } from '../elements';
import styles from './BrowseBreadcrumbs.scss';

type Breadcrumb = { description: string, destination: ?string}
type BrowseBreadcrumbsProps = { breadcrumbs: Array<Breadcrumb | Breadcrumb[]> }

const BrowseBreadcrumbs = ({breadcrumbs}: BrowseBreadcrumbsProps) => {
  return (
    <ol className={styles.cmBreadcrumb_ListContainer}>
      {breadcrumbs.map((breadcrumb, index) => (
        <WithSplitter key={index}>
          {Array.isArray(breadcrumb)
            ? <li><BrowseBreadcrumbSiblings breadcrumb_siblings={breadcrumb} /></li>
            : <li><BrowseBreadcrumb breadcrumb={breadcrumb} /></li>}
        </WithSplitter>
      ))}
    </ol>
  );
};

type BrowseBreadcrumbSiblingsProps = {breadcrumb_siblings: Breadcrumb[]};
const BrowseBreadcrumbSiblings = ({breadcrumb_siblings}: BrowseBreadcrumbSiblingsProps) => {
  return breadcrumb_siblings.map(breadcrumb_sibling => (
    <WithSiblingSplitter key={breadcrumb_sibling.description}>
      <BrowseBreadcrumb breadcrumb={breadcrumb_sibling} />
    </WithSiblingSplitter>
  ));
};
type BrowseBreadcrumbProps = {breadcrumb: Breadcrumb};
const BrowseBreadcrumb = ({breadcrumb}: BrowseBreadcrumbProps) => {
  const { description, destination } = breadcrumb;

  if (!destination){
    return <MBText.Span className={styles.cmBreadcrumb_Element}>{description}</MBText.Span>;
  } else {
    return (
      <MBLink.Text href={destination} className={styles.cmBreadcrumb_Element}>
        {description}
      </MBLink.Text>
    );
  }
};

const WithSplitter = ({children}) => {
  return (
    <React.Fragment>
      <li className={styles.cmBreadcrumb_SplitterContainer}>
        <MBText.Span className={styles.cmBreadcrumb_Splitter}>&ensp;›&ensp;</MBText.Span>
      </li>
      {children}
    </React.Fragment>
  );
};

const WithSiblingSplitter = ({children}) => {
  return (
    <React.Fragment>
      <MBText.Span className={styles.cmBreadcrumb_SiblingSplitter}>, </MBText.Span>
      {children}
    </React.Fragment>
  );
};

export default BrowseBreadcrumbs;

export const formatProductTypeDestination = (...permalinks: string[]) => `/store/category/${permalinks.join('/')}`;
