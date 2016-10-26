/*-----------------------------------------------------------------------------
| Copyright (c) 2014-2015, PhosphorJS Contributors
|
| Distributed under the terms of the BSD 3-Clause License.
|
| The full license is in the file LICENSE, distributed with this software.
|----------------------------------------------------------------------------*/
'use strict';

import {
  Widget
} from 'phosphor-widget';

import {
  DockPanel
} from '../lib/index';

import './index.css';


function createContent(title: string): Widget {
  let widget = new Widget();
  widget.addClass('content');
  widget.addClass(title.toLowerCase());
  widget.title.text = title;
  widget.title.closable = true;
  return widget;
}


function main(): void {
  let r1 = createContent('Red');
  let r2 = createContent('Red');
  let r3 = createContent('Red');

  let b1 = createContent('Blue');
  let b2 = createContent('Blue');
  let b3 = createContent('Blue');

  let g1 = createContent('Green');
  let g2 = createContent('Green');
  let g3 = createContent('Green');

  let y1 = createContent('Yellow');
  let y2 = createContent('Yellow');
  let y3 = createContent('Yellow');

  let panel = new DockPanel();
  panel.id = 'main';

  panel.insertLeft(r1);

  panel.insertRight(b1, r1);
  panel.insertBottom(y1, b1);
  panel.insertLeft(g1, y1);

  panel.insertBottom(b2);

  panel.insertTabBefore(y2, r1);
  panel.insertTabBefore(b3, y2);
  panel.insertTabBefore(g2, b2);
  panel.insertTabBefore(y3, g2);
  panel.insertTabBefore(g3, y3);
  panel.insertTabBefore(r2, b1);
  panel.insertTabBefore(r3, y1);

  panel.attach(document.body);

  window.onresize = () => { panel.update(); };
}


window.onload = main;
