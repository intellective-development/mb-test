// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import type { ContentLayout } from 'store/business/content_layout';

import { content_layout_actions } from 'store/business/content_layout';
import { session_selectors } from 'store/business/session';
import { supplier_selectors } from 'store/business/supplier';
import { request_status_constants, request_status_selectors } from 'store/business/request_status';
import { MBErrorBoundary } from '../../elements';

type ContentLayoutProps = {
  can_fetch_without_suppliers: boolean,

  // STP
  content_layout: ContentLayout,
  request_status: string,
  has_checked_for_suppliers: boolean,
  has_suppliers: boolean,
  // DTP
  fetchContentLayout: () => void,
};

const withContentLayout = (page_name: string) => (WrappedComponent: React.ComponentType<PropsOutput>) => { // TODO: use a generic type here, enforce that it gets the layout and its request_status attached
  const wrapped_component_name: string = WrappedComponent.displayName || WrappedComponent.name || 'Component';

  class ContentLayoutFetcher extends React.Component<ContentLayoutProps> {
    static displayName = `WithCL(${wrapped_component_name})`

    componentDidMount(){
      this.attemptLayoutFetch(this.props);
    }

    componentWillReceiveProps(next_props: ContentLayoutProps){
      this.attemptLayoutFetch(next_props);
    }

    attemptLayoutFetch = (curr_props: ContentLayoutProps) => {
      const { content_layout, request_status, has_suppliers, can_fetch_without_suppliers, has_checked_for_suppliers, fetchContentLayout } = curr_props;

      const is_loading = request_status === request_status_constants.LOADING_STATUS;
      const has_error = request_status === request_status_constants.ERROR_STATUS;
      const suppliers_valid = has_checked_for_suppliers && (has_suppliers || can_fetch_without_suppliers);
      const should_fetch = !content_layout && !is_loading && !has_error && suppliers_valid;
      if (should_fetch) fetchContentLayout();
    }

    errorBoundaryData = () => ({
      location: 'Content Layout',
      page_name,
      props: this.props
    })

    render(){
      const { content_layout, request_status, ...rest_props } = this.props;
      const wrapped_component_props = _.omit(rest_props, 'has_checked_for_suppliers', 'fetchContentLayout');

      return (
        <MBErrorBoundary errorData={this.errorBoundaryData}>
          <WrappedComponent
            {...wrapped_component_props}
            content_layout={content_layout}
            content_layout_request_status={request_status} />
        </MBErrorBoundary>
      );
    }
  }

  const contentLayoutSTP = () => {
    const findContentLayout = Ent.query(Ent.find('content_layout'), Ent.join('content', 'content_module'));

    return (state, {content_layout_id}) => ({
      content_layout: findContentLayout(state, content_layout_id),
      request_status: request_status_selectors.getContentLayoutStatus(state, content_layout_id),
      has_checked_for_suppliers: session_selectors.hasCheckedForSuppliers(state),
      has_suppliers: supplier_selectors.hasCurrentSuppliers(state)
    });
  };

  const contentLayoutDTP = (dispatch, {content_layout_id, context = {}}) => ({
    fetchContentLayout: () => dispatch(content_layout_actions.fetchContentLayout(content_layout_id, page_name, context))
  });

  return connect(contentLayoutSTP, contentLayoutDTP)(ContentLayoutFetcher);
};

export default withContentLayout;
