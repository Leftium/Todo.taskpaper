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

    onAfterAttach: (msg) =>
        super()

    render: (text) =>
        text ||= @syncMaster.data
        # loosely based on:
        # https://github.com/jessegrosjean/birch-outline/blob/master/doc/getting-started.md

        taskPaperOutline = new birch.Outline.createTaskPaperOutline(text)
        ul = document.createElement('ul')

        item = taskPaperOutline.root
        while (item = item.nextItem)
            itemLI = document.createElement('li')
            for attribute in item.attributeNames
                itemLI.setAttribute attribute, item.getAttribute(attribute)
            itemLI.setAttribute 'depth', item.depth
            itemLI.innerHTML = item.bodyHighlightedAttributedString
                                   .toInlineBMLString()

            ul.appendChild(itemLI)

        @$node.empty()
        @$node.append(ul)
        @node.innerHTML = linkifyHtml @node.innerHTML, @linkifyOptions



