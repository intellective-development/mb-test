// @flow

import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import { MBLayout, MBHeader } from '../../elements';
import CocktailTile from './CocktailTile';
import styles from './CocktailScroller.scss';

const cn = bindClassNames(styles);

class CocktailScroller extends React.Component {
  state = {
    type: ''
  }

  render(){
    const { internal_name, action_name, action_url, title, debug_layout, cocktails } = this.props;
    const { type } = this.state;
    const image_tiles = cocktails.map(cocktail => (
      <CocktailTile
        key={cocktail.id}
        {...cocktail}
        internal_name={internal_name}
        className={cn('cmProductScroller_Tile')} />
    ));

    return (
      <MBLayout.StandardGrid className={cn('cmProductScroller cocktails-list')}>
        { debug_layout ? <div>
          <button className={type === '' ? 'elMBButton__Hollow' : ''} onClick={() => { this.setState({ type: '' }); }}>flex-box-grid</button>
          <button className={type === 'ratio' ? 'elMBButton__Hollow' : ''} onClick={() => { this.setState({ type: 'ratio' }); }}>maintain ratio</button>
          <button className={type === 'fixed-size' ? 'elMBButton__Hollow' : ''} onClick={() => { this.setState({ type: 'fixed-size' }); }}>fixed size</button>
        </div> : null }

        <MBHeader
          action_url={action_url}
          action_name={action_name}
          title={title} />

        <div className={`cocktail-list-grid ${type}`}>
          {image_tiles}
        </div>
      </MBLayout.StandardGrid>
    );
  }
}

export default CocktailScroller;
