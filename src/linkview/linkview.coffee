# PhosphorJS widget that hosts rendering of a Taskpaper Outline.

# To temporarily introspect variables during development.
spy = window
slog = console.log # spy + log

import { Widget }   from 'phosphor-widget'

import * as birch   from 'birch-outline'

import * as linkify from 'linkifyjs'
import linkifyHtml  from 'linkifyjs/html'

import './linkview.css'

# class LinkView extends SyncView


export class LinkViewWidget extends Widget
    constructor: (syncMaster) ->
        super()
        @addClass('LinkViewWidget')
        @$node = $(@node)
        @maxLength = 50

    onResize: (msg) =>
        super()

    onAfterAttach: (msg) =>
        super()

    render: (startText) =>
      startText = startText or ''
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
      @node.innerHTML = linkifyHtml @node.innerHTML, options =
        attributes: (href) ->
            attributes =
                title: href
        format: (value) =>

            constructUrl = (head, tail) ->
                if tail.length
                    head.concat(tail).join('/')
                else
                    head.join('/')

            truncate = (string, length) ->
                if string.length > length
                    string = string[0...length-1] + '…'
                string


            # Strip URL hash, query strings, http, www, trailing slash
            value = value.split('#')[0]
                         .split('?')[0]
                         .replace ///^https?://(www[0-9]*\.)?///i, ''
                         .replace ////$///i, ''


            # If URL short enough, don't shorten
            if value.length < @maxLength
                return value

            parts = value.split('/')

            # Start with the domain
            head = parts.splice(0, 1)
            tail = []

            # strip file extension
            lastPart = parts.pop()
            lastPart = lastPart?.replace ///(index)?\.[a-z]+$///i, ''
            if lastPart
                parts.push(lastPart)

            # Append very last URL fragment, truncating if required
            lengthLeft = @maxLength - constructUrl(head, tail).length
            if lengthLeft > 0 and parts.length
                fragment = parts.pop()
                tail.push(truncate(fragment, lengthLeft))

            # Insert very first URL fragment, truncating if required
            lengthLeft = @maxLength - constructUrl(head, tail).length
            if lengthLeft > 0 and parts.length
                fragment = parts.shift()
                head.push(truncate(fragment, lengthLeft))

            if parts.length
                head.push('\u22EF')  # Midline horizontal ellipsis ⋯

            constructUrl(head, tail)



