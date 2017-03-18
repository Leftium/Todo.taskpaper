# PhosphorJS widget that hosts rendering of a Taskpaper Outline.

# To temporarily introspect variables during development.
spy = window
slog = console.log # spy + log

import { Widget }   from 'phosphor-widget'

import * as birch   from 'birch-outline'

import * as linkify from 'linkifyjs'
import linkifyHtml  from 'linkifyjs/html'

import Clusterize   from 'clusterize.js'
spy.Clusterize = Clusterize

import 'clusterize.js/clusterize.css'
import './linkview.css'


# class LinkView extends SyncView

htmlFragment = '''
    <div class="clusterize-scroll">
      <ul class="clusterize-content">
        <li class="clusterize-no-data">Loading data…</li>
      </ul>
    </div>
    '''

export class LinkViewWidget extends Widget
    constructor: (syncMaster) ->
        super()
        @addClass('LinkViewWidget')
        @$node = $(@node)
        @syncMaster = syncMaster


        @maxLength = 50
        @linkifyOptions =
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

    onResize: (msg) =>
        super()
        @clusterize?.refresh()


    onAfterAttach: (msg) =>
        super()

    render: (text) =>
        text ||= @syncMaster.data
        # loosely based on:
        # https://github.com/jessegrosjean/birch-outline/blob/master/doc/getting-started.md

        taskPaperOutline = new birch.Outline.createTaskPaperOutline(text)
        ul = document.createElement('ul')

        items = []

        itemPath = @itemPath or '*'
        results = taskPaperOutline.evaluateItemPath(itemPath)

        if itemPath isnt '*'
            itemLI = document.createElement('li')
            itemLI.innerHTML = "ItemPath: #{itemPath} (#{results.length} results)<br><hr>"
            items.push(itemLI.outerHTML)

        knownParents =
            'Birch': true

        addItem = (item) =>
            knownParents[item.id] = true
            if item.parent and not knownParents[item.parent.id]
                addItem(item.parent)

            itemLI = document.createElement('li')
            for attribute in item.attributeNames
                itemLI.setAttribute attribute, item.getAttribute(attribute)
            itemLI.setAttribute 'depth', item.depth
            itemLI.innerHTML = item.bodyHighlightedAttributedString
                                   .toInlineBMLString() or '&nbsp;'

            items.push(linkifyHtml itemLI.outerHTML, @linkifyOptions)

        for item in results
            addItem(item)

        @$node.empty()
        @$node.append(htmlFragment)

        @clusterize = new Clusterize options =
            rows: items
            scrollElem: $('.clusterize-scroll', @node)[0]
            contentElem: $('.clusterize-content', @node)[0]

    search: (itemPath) =>
        @itemPath = itemPath
        @render()

