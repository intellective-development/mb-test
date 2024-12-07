import {
  initialState,
  getNextItemIndex,
  makeSelectIndexState,
  makeDisplayFewerItemsState,
  makeDisplayMoreItemsState
} from '../selectable_list';

describe('selectable list component', () => {
  // These are slightly experimental. In theory, they should always pass.
  // https://hexdocs.pm/stream_data/ExUnitProperties.html
  describe('property based tests', () => {
    describe('initialState', () => {
      describe('initial displayed_item_indices value', () => {
        let random_display_count;

        random_display_count = Math.floor(Math.random() * 100);
        it(`should create an array the length of the display count (tested with ${random_display_count})`, () => {
          const random_props = { display_count: random_display_count };
          const random_state = initialState(random_props);
          expect(random_state.displayed_item_indices.length).toEqual(random_props.display_count);
        });

        random_display_count = Math.ceil(Math.random() * 100);
        it(`should populate the array with integers, starting at 0 (tested with ${random_display_count})`, () => {
          const random_props = { display_count: random_display_count };
          const random_state = initialState(random_props);

          if (random_props.display_count === 0){
            expect(random_state.displayed_item_indices[0]).toBeUndefined();
          } else {
            expect(random_state.displayed_item_indices[0]).toEqual(0);
          }
        });

        random_display_count = Math.floor(Math.random() * 100);
        it(`should populate the array with integers, each increasing by 1 (tested with ${random_display_count})`, () => {
          const random_props = { display_count: random_display_count };
          const random_state = initialState(random_props);
          random_state.displayed_item_indices.forEach((value, index) => expect(value).toEqual(index));
        });
      });
    });
  });

  describe('initialState', () => {
    describe('initial displayed_item_indices value', () => {
      it('should create an array the length of the display count', () => {
        const props = { display_count: 5 };
        const state = initialState(props);
        expect(state.displayed_item_indices.length).toEqual(5);
      });

      it('should populate the array with integers starting at 0 and increasing by 1', () => {
        const props = { display_count: 5 };
        const state = initialState(props);
        expect(state.displayed_item_indices).toEqual([0, 1, 2, 3, 4]);
      });

      it('should be able to handle empty values', () => {
        const props = { display_count: 0 };
        const state = initialState(props);
        expect(state.displayed_item_indices).toEqual([]);
      });
    });
  });

  describe('getNextItemIndex', () => {
    it('should select a larger index if possible', () => {
      const current_index = 3;
      const displayed_item_indices = [0, 1, 2, 3];
      const item_count = 10;

      const next_index = getNextItemIndex(current_index, displayed_item_indices, item_count);
      expect(next_index).toEqual(4);
    });

    it('should loop back to the beginning if no larger indices possible', () => {
      const current_index = 3;
      const displayed_item_indices = [1, 2, 3];
      const item_count = 4;

      const next_index = getNextItemIndex(current_index, displayed_item_indices, item_count);
      expect(next_index).toEqual(0);
    });

    it('should skip already displayed indices', () => {
      const current_index = 3;
      const displayed_item_indices = [0, 1, 2, 3, 4];
      const item_count = 10;

      const next_index = getNextItemIndex(current_index, displayed_item_indices, item_count);
      expect(next_index).toEqual(5);
    });

    it('should return undefined if all values are already selected', () => {
      const current_index = 3;
      const displayed_item_indices = [0, 1, 2, 3, 4];
      const item_count = 5;

      const next_index = getNextItemIndex(current_index, displayed_item_indices, item_count);
      expect(next_index).toBeUndefined();
    });
  });

  describe('makeSelectIndexState', () => {
    it('should do nothing if the display count is greater than the number of items', () => {
      const props = { items: [], display_count: 5 };
      const state = initialState(props);

      expect(makeSelectIndexState(0)(state, props)).toEqual(state);
    });

    it('should do nothing if the display count is equal to the number of items', () => {
      const props = { items: [0, 1, 2, 3, 4], display_count: 5 };
      const state = initialState(props);

      expect(makeSelectIndexState(0)(state, props)).toEqual(state);
    });

    it('should replace the selected item and get the next item index if possible', () => {
      const props = { items: [0, 1, 2, 3, 4], display_count: 2 };
      const state = initialState(props);

      // initial state is:
      // {
      //    displayed_item_indices: [0, 1],
      //    next_item_index: 2
      // }
      expect(makeSelectIndexState(0)(state, props)).toEqual({
        displayed_item_indices: [2, 1],
        next_item_index: 3
      });
    });
  });

  describe('makeDisplayFewerItemsState', () => {
    it('should remove items from the end of the displayed_item_indices array', () => {
      const props = { items: [0, 1, 2, 3, 4], display_count: 4 };
      const next_props = { items: [0, 1, 2, 3, 4], display_count: 2 };
      const state = initialState(props);
      const next_state = makeDisplayFewerItemsState(props, next_props)(state);

      // initial state is:
      // {
      //    displayed_item_indices: [0, 1, 2, 3],
      //    next_item_index: 4
      // }
      expect(next_state).toEqual({
        displayed_item_indices: [0, 1],
        next_item_index: 4
      });
    });
  });

  describe('makeDisplayMoreItemsState', () => {
    it('should add items to the end of the displayed_item_indices array and update the next_item_index', () => {
      const props = { items: [0, 1, 2, 3, 4], display_count: 2 };
      const next_props = { items: [0, 1, 2, 3, 4], display_count: 4 };
      const state = initialState(props);
      const next_state = makeDisplayMoreItemsState(props, next_props)(state);

      // initial state is:
      // {
      //    displayed_item_indices: [0, 1],
      //    next_item_index: 4
      // }
      expect(next_state).toEqual({
        displayed_item_indices: [0, 1, 2, 3],
        next_item_index: 4
      });
    });
  });
});
