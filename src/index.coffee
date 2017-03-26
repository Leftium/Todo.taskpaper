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
import { parse as parseQueryString } from 'querystring'

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

        editor = textView.editor

        editor.on 'changes', (cm, changes) =>
            for change,i in changes
                slog.editor 'change', i
                slog.editor 'from:   ', change.from
                slog.editor 'to:     ', change.to
                slog.editor 'text:   ', change.text
                slog.editor 'origin: ', change.origin

        return textView


    expose.makeConsole = (title='Console', closable=true) ->
        consoleView = new CoffeeConsoleWidget()
        consoleView.title.text = title
        consoleView.title.closable = closable
        return consoleView


    initPanel = () ->
        slog "initPanel()"

        # Initialize outline
        outline = new birch.Outline.createTaskPaperOutline("")
        outline.onDidEndChanges () =>
            @update(@outline.serialize())

        expose.outline = outline


        panel = new DockPanel()
        panel.id = 'main'
        panel.attach(document.body)
        window.onresize = () -> panel.update()
        spy.panel = panel

        spy.coffeeConsole = makeConsole()
        linkView = new LinkViewWidget()
        linkView.title.text = 'Link View'
        linkView.title.closable = true

        spy.textView = makeTextView()

        spy.cc = spy.coffeeConsole = coffeeConsole
        spy.tv = spy.textView = textView
        spy.lv = spy.linkView = linkView


        panel.insertRight(textView)
        panel.insertBottom(coffeeConsole, textView)
        panel.insertLeft(linkView)

        # adjust panel sizes
        panel.layout._children[0].setSizes([4,6])
        panel.layout._children[0].layout._children[1].setSizes([6,4])

    hashKeys = parseQueryString(location.hash[1...])

    # Initialize access token, preferring token in URL query string
    accessToken = hashKeys.access_token
    accessToken = accessToken || localStorage.accessToken
    # Cache value for future use
    if accessToken?
        localStorage.accessToken = accessToken

    path = hashKeys?.state or location.hash[1...].split('&')[0]

    if script = hashKeys.coffee or hashKeys.cs
        expose.birch = birch
        expose.outline = outline
        log 'CoffeeScript detected in hash:'

        script = script.replace(/^>/, '')
        lines = script.split('\n>')

        amplify.subscribe 'outline-ready', () =>
            for line in lines
                log "      > #{line}"
                $$.addToSaved(line)
                $$.processSaved(line)

    if path is '/' or path is ''
        path = 'WELCOME'
    history.pushState(null, null, "##{path}")

    exposeVariables = () =>

        expose.amplify = amplify

        spy.parseQueryString = parseQueryString

        spy.hashKeys = hashKeys
        spy.path = path

    initPanel()
    exposeVariables()


window.onload = main

