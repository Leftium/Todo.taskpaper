# PhosphorJS widget that hosts rendering of a Taskpaper Outline.

import { Widget }   from 'phosphor-widget'

import * as birch                    from 'birch-outline'

import './linkview.css'

# class LinkView extends SyncView


export class LinkViewWidget extends Widget
    constructor: (syncMaster) ->
        super()
        @addClass('LinkViewWidget')
        @$node = $(@node)

    onResize: (msg) =>
        super()

    onAfterAttach: (msg) =>
        super()

    render: (startText) =>
      startText = startText or 'one:\n\t- two\n\t\tthree\n\t\tfour @done\n\t- five\n\t\tsix'
      # based on: https://github.com/jessegrosjean/birch-outline/blob/master/doc/getting-started.md
      `
      var taskPaperOutline = new birch.Outline.createTaskPaperOutline(startText);
      var item = taskPaperOutline.root.firstChild;

      function insertChildren(item, parentUL) {
        item.children.forEach(function (each) {
          var itemLI = document.createElement('li');
          each.attributeNames.forEach(function(eachAttribute) {
            itemLI.setAttribute(eachAttribute, each.getAttribute(eachAttribute));
          });

          var itemBodyP = document.createElement('p');
          itemBodyP.innerHTML = each.bodyHighlightedAttributedString.toInlineBMLString();
          itemLI.appendChild(itemBodyP);

          var itemChildrenUL = document.createElement('ul');
          insertChildren(each, itemChildrenUL);
          if (itemChildrenUL.firstChild) {
            itemLI.appendChild(itemChildrenUL);
          }

          parentUL.appendChild(itemLI);
        });
      };
      `
      ul = document.createElement('ul')
      insertChildren(taskPaperOutline.root, ul)
      @$node.empty()
      @$node.append(ul)


