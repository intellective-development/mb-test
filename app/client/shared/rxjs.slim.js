// rxjs 5 introduced the ability to reduce build sizes by selectively importing only the components that we need.
// We use that here, creating a manifest  of the operators and constructors that we like, reducing both its memory and cognitive footprint.

// rxjs full is not a real dependency (its a webpack alias) to eslint doesn't like it
/* eslint-disable import/no-unresolved */
/* eslint-disable import/no-extraneous-dependencies */
/* eslint-disable import/extensions */

// we grab all of the objects we want from RX
import { Observable } from 'rxjs-full/Observable';
import { Subject } from 'rxjs-full/Subject';
import { BehaviorSubject} from 'rxjs-full/BehaviorSubject';
import { ReplaySubject } from 'rxjs-full/ReplaySubject'; // should look to convert these to BehaviorSubjects, import adds some weight

// we use the add files to pull in only the functions we want
import 'rxjs-full/add/observable/of';
import 'rxjs-full/add/observable/from';
import 'rxjs-full/add/observable/interval';
import 'rxjs-full/add/observable/merge';
import 'rxjs-full/add/observable/combineLatest';
import 'rxjs-full/add/observable/concat';

import 'rxjs-full/add/operator/do';
import 'rxjs-full/add/operator/filter';
import 'rxjs-full/add/operator/map';
import 'rxjs-full/add/operator/reduce';
import 'rxjs-full/add/operator/take';
import 'rxjs-full/add/operator/scan';

import 'rxjs-full/add/operator/skip';
import 'rxjs-full/add/operator/startWith';
import 'rxjs-full/add/operator/distinctUntilChanged';
import 'rxjs-full/add/operator/delay';
import 'rxjs-full/add/operator/debounceTime';
import 'rxjs-full/add/operator/catch';
import 'rxjs-full/add/operator/merge';
import 'rxjs-full/add/operator/concat';
import 'rxjs-full/add/operator/mergeMap';
import 'rxjs-full/add/operator/switchMap';
import 'rxjs-full/add/operator/combineLatest';
import 'rxjs-full/add/operator/withLatestFrom';
import 'rxjs-full/add/operator/toPromise';

// we re-export a single object, to match the original rxjs import
export default {
  Observable,
  Subject,
  BehaviorSubject,
  ReplaySubject
};
