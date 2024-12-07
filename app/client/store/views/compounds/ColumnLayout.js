// @flow
// This module renders other ContentModules from its own ContentLayout within columns
// The columns are defined by its column_section_ids prop
// It grabs any ContentModules in the redux store that have a matching section_id property
// and belong to the content layout specified by its content_layout_id prop

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { content_module_helpers } from 'store/business/content_module';
import type { ContentModule as ContentModuleType } from 'store/business/content_module';
import { MBLayout, MBGrid } from '../elements';
import ContentModule from './GenericContentModule';

type ColumnLayoutProps = {
  column_section_ids: string[],
  content_layout_id: string,
  content_modules: ContentModuleType[]
}

type ColumnProps = {
  column_layout_id: string,
  content_modules: ContentModuleType[]
}

const Column = ({ content_modules, column_layout_id }: ColumnProps) => (
  <MBGrid.Element
    className={'cm-col-layout__col'}>
    {content_modules.map((content_module) => (
      <div key={content_module.internal_name} className="cm-col-layout__content-module">
        <ContentModule
          key={content_module.internal_name}
          content_layout_id={column_layout_id}
          content_module={content_module} />
      </div>
    ))}
  </MBGrid.Element>
);

const ColumnLayout = ({ column_section_ids, column_layout_id, content_modules }: ColumnLayoutProps) => {
  const columns = content_module_helpers.groupContentModulesBySection(content_modules);
  const number_of_columns = column_section_ids.length;

  return (
    <MBLayout.StandardGrid>
      <MBGrid
        className="cm-col-layout"
        cols={1}
        medium_cols={Math.min(number_of_columns, 2)}
        large_cols={number_of_columns}>
        {column_section_ids.filter(column_id => !!columns[column_id]).map((column_id) => (
          <Column
            key={columns[column_id].map(content_module => content_module.internal_name).join('-')}
            column_layout_id={column_layout_id}
            content_modules={columns[column_id]} />
        ))}
      </MBGrid>
    </MBLayout.StandardGrid>
  );
};

const ColumnLayoutSTP = () => {
  const findContentLayout = Ent.query(Ent.find('content_layout'), Ent.join('content', 'content_module'));

  return (state, ownprops) => ({
    content_modules: findContentLayout(state, ownprops.content_layout_id).content
  });
};

export default connect(ColumnLayoutSTP)(ColumnLayout);
