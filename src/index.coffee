# Based on http://phosphorjs.github.io/examples/dockpanel/

# To explicitly expose variables. (Acessible from the CoffeeConsole.)
expose = window

import { DockPanel }           from 'phosphor-dockpanel'
import { CodeMirrorWidget }    from 'phosphor-codemirror'

import { CoffeeConsoleWidget } from './coffeeconsole/coffeeconsole.coffee'

import { amplify }             from 'node-amplifyjs/lib/amplify.core.js'
import * as Birch              from 'birch-outline'

import CodeMirror              from 'codemirror'

import 'codemirror/mode/coffeescript/coffeescript'
import 'codemirror/mode/css/css'

import 'codemirror/addon/fold/foldcode.js'
import 'codemirror/addon/fold/indent-fold.js'
import 'codemirror/addon/fold/foldgutter.js'

import 'codemirror/addon/fold/foldgutter.css'
import 'codemirror/lib/codemirror.css'
import './index.css'


expose.birch = Birch
expose.amplify = amplify

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

# helper method to maintain sync between console and editor
expose.setOutline = (contents) ->
    expose.outline = new birch.Outline.createTaskPaperOutline(contents)
    expose.outline.onDidEndChanges () ->
        amplify.publish 'outline-changed', 'outline'

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
    cmTaskpaper.loadTarget './todo.taskpaper', () ->
        contents = doc.getValue()
        setOutline(contents)

    expose.doc = cmTaskpaper.editor.doc
    expose.doc.on 'change', () =>
        amplify.publish 'outline-changed', 'doc'

    cmTaskpaper.title.text = 'CodeMirror View'

    panel.insertLeft(cmTaskpaper)
    panel.insertBottom(coffeeconsole, cmTaskpaper)
    panel.attach(document.body)

    window.onresize = () -> panel.update()

    amplify.subscribe 'outline-changed', (source) ->
        if source isnt 'doc' and expose.doc and expose.outline
            expose.doc.setValue(outline.serialize())
        if source isnt 'outline' and expose.doc and expose.outline
            setOutline(expose.doc.getValue())

window.onload = main
