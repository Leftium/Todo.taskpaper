# Based on http://phosphorjs.github.io/examples/dockpanel/

# To explicitly expose variables. (Acessible from the CoffeeConsole.)
expose = window

# To temporarily introspect variables during development.
spy = window
slog = console.log # spy + log

import { DockPanel }                 from 'phosphor-dockpanel'
import { CodeMirrorWidget }          from 'phosphor-codemirror'

import { CoffeeConsoleWidget }       from './coffeeconsole/coffeeconsole.coffee'

import { amplify }                   from 'node-amplifyjs/lib/amplify.core.js'
import { parse as parseQueryString } from 'querystring'

import * as birch                    from 'birch-outline'

import CodeMirror                    from 'codemirror'
import Dropbox                       from 'dropbox'

import 'codemirror/mode/coffeescript/coffeescript'
import 'codemirror/mode/css/css'

import 'codemirror/addon/fold/foldcode.js'
import 'codemirror/addon/fold/indent-fold.js'
import 'codemirror/addon/fold/foldgutter.js'

import 'codemirror/addon/fold/foldgutter.css'
import 'codemirror/lib/codemirror.css'
import './index.css'


#
# Inject a method to load a file via AJAX.
#
CodeMirrorWidget.prototype.loadTarget = (target, callback) ->
    doc = @_editor.getDoc()
    xhr = new XMLHttpRequest()
    xhr.open('GET', target)
    xhr.onreadystatechange = () ->
        doc.setValue(xhr.responseText)
        if xhr.readyState is XMLHttpRequest.DONE and
           typeof callback is 'function'
            callback()
    xhr.send()

#
# The main application entry point.
#
main = () ->
    panel = new DockPanel()
    panel.id = 'main'

    coffeeconsole = new CoffeeConsoleWidget()
    coffeeconsole.title.text = 'CoffeeScript REPL'

    cmTaskpaper = new CodeMirrorWidget({
        mode: 'text/plain'
        lineNumbers: true
        foldGutter:
            rangeFinder: CodeMirror.fold.indent
        gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter']
        tabSize: 4
    })

    # Initialize CodeMirror document
    doc = cmTaskpaper.editor.doc
    doc.on 'change', () =>
        amplify.publish 'outline-changed', doc.changeGeneration(), 'doc.change'

    # Initialize outline
    outline = new birch.Outline.createTaskPaperOutline(doc.getValue())
    outline.generation = doc.changeGeneration()
    outline.onDidEndChanges () ->
        outline.generation++
        amplify.publish 'outline-changed', outline.generation, 'outline.onDidEndChanges'

    cmTaskpaper.title.text = 'CodeMirror View'
    panel.insertLeft(cmTaskpaper)
    panel.insertBottom(coffeeconsole, cmTaskpaper)
    panel.attach(document.body)

    window.onresize = () -> panel.update()

    amplify.subscribe 'outline-changed', (generation, source) ->
        # console.log 'outline-changed', generation, source
        if not doc.isClean(generation)
            doc.setValue(outline.serialize())
        if generation > outline.generation # and expose.doc and expose.outline
            outline.reloadSerialization(doc.getValue())

    loadDefault = () ->
        cmTaskpaper.loadTarget './todo.taskpaper', () ->
            contents = doc.getValue()

    hashKeys = parseQueryString(location.hash[1...])

    # Initialize access token, preferring token in URL query string
    accessToken = hashKeys.access_token
    accessToken = accessToken || localStorage.accessToken
    # Cache value for future use
    if accessToken?
        localStorage.accessToken = accessToken

    dbx = new Dropbox options =
        clientId: '4lvqqk59oy9o23n'
        accessToken: accessToken

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

    authenticationUrl = dbx.getAuthenticationUrl(location.href.split("#")[0], path or 'WELCOME')
    authenticationLink = "<a href='#{authenticationUrl}'>#{authenticationUrl}</a>"

    # User chose not to give access to Dropbox account
    dropboxAccessDenied = hashKeys.error is 'access_denied'
    if dropboxAccessDenied
        location.hash = 'BLANK'
        path = 'BLANK'
        log """

            ATTENTION: You chose not to give access to your Dropbox account.
            To give access later, just follow this link:
            #{authenticationLink}

            """

    if path is '/' or path is ''
        path = 'WELCOME'

    location.hash = path
    switch path
        when 'WELCOME'
            loadDefault()
            amplify.publish 'outline-ready'
        when 'BLANK', 'NEW', 'DEMO'
            amplify.publish 'outline-ready'





    expose.doc = doc
    expose.outline = outline

    expose.amplify = amplify

    spy.parseQueryString = parseQueryString
    spy.Dropbox = Dropbox

    spy.coffeeconsole = coffeeconsole
    spy.hashKeys = hashKeys
    spy.path = path
    spy.dbx = dbx
    spy.authenticationUrl = authenticationUrl
    spy.dropboxAccessDenied = dropboxAccessDenied

window.onload = main

