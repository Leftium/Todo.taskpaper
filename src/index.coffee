# Based on http://phosphorjs.github.io/examples/dockpanel/

# To explicitly expose variables. (Acessible from the CoffeeConsole.)
expose = window

# To temporarily introspect variables during development.
spy = window

slogTags =
  ALL: 1


# spy + log
slog = () =>
    args = if arguments.length is 1 then [arguments[0]] else Array.apply(null, arguments)
    args.unshift("[slog]")
    console.log.apply null, args

sdir = () =>
    args = if arguments.length is 1 then [arguments[0]] else Array.apply(null, arguments)
    args.unshift("[sdir]")
    console.dir.apply null, args

handler = (baseMethod) =>
    object =
        get: (target, name) =>
          if slogTags.ALL or slogTags[name]
            () ->
              args = if arguments.length is 1 then [arguments[0]] else Array.apply(null, arguments)
              args.unshift("@#{name}")
              baseMethod.apply null, args
          else
            () -> true

slog = new Proxy(slog, handler(console.log))
sdir = new Proxy(sdir, handler(console.log))

window.slog = slog

slog 'no tags'
slog.tag 'tagged', 'two args'



slog = new Proxy(slog, handler)

window.slog = slog
# slog = () -> null


import { welcomeTaskpaper }          from './welcome-taskpaper.coffee'
import { DockPanel }                 from 'phosphor-dockpanel'
import { CodeMirrorWidget }          from 'phosphor-codemirror'

import { CoffeeConsoleWidget }       from './coffeeconsole/coffeeconsole.coffee'
import { LinkViewWidget }            from './linkview/linkview.coffee'

import { amplify }                   from 'node-amplifyjs/lib/amplify.core.js'

import * as birch                    from 'birch-outline'

import CodeMirror                    from 'codemirror'

import 'codemirror/mode/coffeescript/coffeescript'
import 'codemirror/mode/css/css'

import 'codemirror/addon/fold/foldcode.js'
import 'codemirror/addon/fold/indent-fold.js'
import 'codemirror/addon/fold/foldgutter.js'

import 'codemirror/addon/fold/foldgutter.css'
import 'codemirror/theme/solarized.css'
import './normalize.css'
import './index.css'

publishUpdates = true

#
# The main application entry point.
#
main = () ->
    expose.makeTextView = (title='Text View', closable=true) ->
        textView = new CodeMirrorWidget options =
            theme: 'solarized light'
            mode: 'text/plain'
            lineNumbers: true
            foldGutter:
                rangeFinder: CodeMirror.fold.indent
            gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter']
            tabSize: 4

        textView.title.text = title
        textView.title.closable = closable

        expose.editor = textView.editor

        editor.on 'beforeChange', (cm, change) =>
            if publishUpdates
                amplify.publish 'before-updated-editor', editor, change

        editor.on 'changes', (cm, changes) =>
            if publishUpdates
                amplify.publish 'updated-editor', editor, changes
        return textView


    expose.makeConsole = (title='Console', closable=true) ->
        consoleView = new CoffeeConsoleWidget()
        consoleView.title.text = title
        consoleView.title.closable = closable
        return consoleView


    initPanel = () ->
        slog "initPanel()"

        expose.itemize = (items) =>
            _itemize = (item) =>
                value = null
                switch typeof item
                    when 'string', 'undefined' 
                        value = outline.createItem(item)
                return value
            if items.constructor is Array
                (_itemize(item) for item in items)
            else
                _itemize(items)

        expose.insertBefore = (items, row) =>
            items = itemize(items)
            referenceItem = outline.items[row]
            outline.insertItemsBefore(items, referenceItem)


        expose.remove = (row) =>
            outline.removeItems(outline.items[row])

        # Initialize outline
        outline = new birch.Outline.createTaskPaperOutline('Row: 1')
        # outline.reloadSerialization('')

        insertBefore("Row: #{r}") for r in [2..3]




        outline.onDidEndChanges (changes) =>
            if publishUpdates
                amplify.publish 'updated-outline', outline, changes

        expose.birch = birch
        expose.outline = outline

        ###
        outline1 = new birch.Outline.createTaskPaperOutline("")
        outline2 = new birch.Outline.createTaskPaperOutline("")
        expose.o1 = outline1
        expose.o2 = outline2
        ###

        panel = new DockPanel()
        panel.id = 'main'
        panel.attach(document.body)
        window.onresize = () -> panel.update()
        spy.panel = panel

        spy.coffeeConsole = makeConsole()
        linkView = new LinkViewWidget()
        linkView.title.text = 'Link View'
        linkView.title.closable = true
        expose.linkview = linkView
        linkView.render(outline)

        spy.textView = makeTextView()
        textView.editor.setValue(outline.serialize())

        spy.cc = spy.coffeeConsole = coffeeConsole
        spy.tv = spy.textView = textView
        spy.lv = spy.linkView = linkView


        panel.insertRight(textView)
        panel.insertBottom(coffeeConsole, textView)
        panel.insertLeft(linkView)

        # adjust panel sizes
        panel.layout._children[0].setSizes([4,6])
        panel.layout._children[0].layout._children[1].setSizes([6,4])


    exposeVariables = () =>
        expose.amplify = amplify







        expose.unshiftItem = (item=outline.createItem('')) =>
            outline.insertItemsBefore(
                item,
                outline.root.nextItem
            )

        expose.shiftItem = () =>
            item = outline.root.nextItem
            outline.removeItems(item)
            item

        expose.appendItem = (item=outline.createItem('')) =>
            outline.insertItemsBefore(
                item
            )

        expose.popItem = () =>
            item = outline.root.lastDescendant
            outline.removeItems(item)
            item

        expose.rollUp = () =>
            shiftItem()
            appendItem()

        expose.rollDown = () =>
            unshiftItem()
            popItem()


    initPanel()
    exposeVariables()

    amplify.subscribe 'before-updated-editor', (editor, change) =>
        slog.editor '--- BEFORE CHANGE -------------------------------------'
        slog.editor 'from:   ', change.from
        slog.editor 'to:     ', change.to
        slog.editor 'text:   ', change.text
        slog.editor 'removed:   ', change.removed
        slog.editor 'origin: ', change.origin

        text = editor.getRange(change.from, change.to)
        slog.editor 'text*: ', [text]

    amplify.subscribe 'updated-editor', (editor, changes) =>
        publishUpdates = false
        for change,i in changes
            slog.editor '--- CHANGE ----------------------------------------', i
            slog.editor 'from:   ', change.from
            slog.editor 'to:     ', change.to
            changeEnd = CodeMirror.changeEnd(change)
            slog.editor 'to*:    ', changeEnd
            slog.editor 'text:   ', change.text
            slog.editor 'removed:   ', change.removed
            slog.editor 'origin: ', change.origin

            text = editor.getRange(change.from, changeEnd)
            slog.editor 'text!: ', [text]

            updateWindow = [0, 0]
            updateWindow[0] = change.from.line
            updateWindow[1] = changeEnd.line
            slog.editor 'update window:', updateWindow


            text = editor.getRange({line: change.from.line, ch: 0}, {line: changeEnd.line})
            slog.editor 'text*: ', [text]

            updateLines = text.split('\n')
            slog.editor 'update lines:', updateLines

            insertPoint = updateWindow[0]
            if change.from.ch isnt 0 or (change.from.line is change.to.line and change.from.ch is change.to.ch and updateLines[0] isnt '')
                insertPoint = updateWindow[0] + 1
                slog.editor 'insert point++'

            slog.editor 'insert point:', insertPoint

            ###
            How many lines to add?
                How many lines to prepend?
                How many lines to append?
            How many lines to remove?

            First row to update?
            Final row to update?

            1. Add lines (to maintain id's)
            2. Remove lines
            3. Shift lines as needed (to align id's with previous content)
            ###

            prependLines = []
            appendLines = []

            prepending = true
            for line,j in updateLines
                prependLines.push(line)


            if not appendLines.shift()
                prependLines.shift()

            slog.editor 'prepend:', prependLines
            slog.editor 'append :', appendLines

            insertBefore(prependLines, insertPoint)
            insertBefore(appendLines, insertPoint+1)


            prependReferenceItem = outline.items[change.from.line]
            appendReferenceItem  = prependReferenceItem?.nextItem

            linesUpdated = change.text.length - 1
            linesNeeded  = linesUpdated
            linesRemoved = change.to.line - change.from.line


            slog.editor 'linesNeeded:  ', linesNeeded
            slog.editor 'linesRemoved: ', linesRemoved

            if linesNeeded > linesRemoved
                linesNeeded -= linesRemoved
                linesRemoved = 0
            else
                linesRemoved -= linesNeeded
                linesNeeded = 0

            slog.editor 'linesNeeded*:  ', linesNeeded
            slog.editor 'linesRemoved*: ', linesRemoved

            while linesRemoved
                linesRemoved--
                remove(updateWindow[1])



            editLines = (i for i in [change.from.line..change.to.line])
            addLines = (i for i in [0...change.text.length])

            slog.editor 'edit: ', editLines
            slog.editor 'add:  ', addLines

            for item,k in outline.items
                item.bodyString = editor.getLine(k)




            linkView.render(outline)
        publishUpdates = true


    amplify.subscribe 'updated-outline', (outline, changes) =>
        publishUpdates = false
        for change,i in changes
            slog.outline 'change', i
            slog.outline change

            switch change.type
                when 'body' or 'attribute'
                    from = { line: change.target.row, ch: 0 }
                    to   = { line: change.target.row, ch: null }
                    indent = '\t'.repeat(change.target.depth - 1)

                    editor.replaceRange("#{indent}#{change.target.bodyString}", from, to)
                when 'children'
                    change.getFlattendedAddedItems()
                    change.getFlattendedRemovedItems()

                    for item,j in change.flattendedAddedItems or []
                        # slog.outline 'item+', j, item
                        slog.outline item.id, item.row, item.bodyString

                        from = { line: item.row, ch: 0 }
                        to   = { line: item.row, ch: null }

                        indent = '\t'.repeat(item.depth - 1)
                        newline = if item.nextItem then '\n' else ''

                        editor.replaceRange("#{indent}#{item.bodyString}#{newline}", from, from)



                    for item,j in (change.flattenedRemovedItems or []).reverse()
                        # slog.outline 'item-', j, item
                        slog.outline item.id, item.row, item.bodyString

                        from = { line: item.row, ch: 0 }
                        to   = { line: item.row + 1, ch: 0}

                        editor.replaceRange('', from, to)


        linkview.render(outline)
        publishUpdates = true






window.onload = main

