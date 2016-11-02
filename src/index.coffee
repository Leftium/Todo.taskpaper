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
    expose.generation++
    expose.outline = new birch.Outline.createTaskPaperOutline(contents)
    expose.outline.onDidEndChanges () ->
        expose.generation++
        amplify.publish 'outline-changed', expose.generation, 'outline.onDidEndChanges'
    amplify.publish 'outline-changed', expose.generation, 'setOutline'

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

    expose.doc = cmTaskpaper.editor.doc
    expose.generation = expose.doc.changeGeneration()
    expose.doc.on 'change', () =>
        amplify.publish 'outline-changed', doc.changeGeneration(), 'doc.change'

    cmTaskpaper.loadTarget './todo.taskpaper', () ->
        contents = doc.getValue()
        expose.generation = expose.doc.changeGeneration()
        setOutline(contents)

    cmTaskpaper.title.text = 'CodeMirror View'

    panel.insertLeft(cmTaskpaper)
    panel.insertBottom(coffeeconsole, cmTaskpaper)
    panel.attach(document.body)

    window.onresize = () -> panel.update()

    amplify.subscribe 'outline-changed', (generation, source) ->
        # console.log 'outline-changed', generation, source
        if not doc.isClean(generation)
            expose.doc.setValue(outline.serialize())
        if generation > expose.generation and expose.doc and expose.outline
            setOutline(expose.doc.getValue())

window.onload = main
