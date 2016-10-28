# Based on http://phosphorjs.github.io/examples/dockpanel/

import { DockPanel }           from 'phosphor-dockpanel'
import { CodeMirrorWidget }    from 'phosphor-codemirror'

import { CoffeeConsoleWidget } from './coffeeconsole/coffeeconsole.coffee'

import CodeMirror              from 'codemirror'

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
CodeMirrorWidget.prototype.loadTarget = (target) ->
    doc = @_editor.getDoc()
    xhr = new XMLHttpRequest()
    xhr.open('GET', target)
    xhr.onreadystatechange = () -> doc.setValue(xhr.responseText)
    xhr.send()

#
# The main application entry point.
#
main = () ->
    panel = new DockPanel()
    panel.id = 'main'

    coffeeconsole = new CoffeeConsoleWidget('Blue')
    coffeeconsole.title.text = 'CoffeeScript REPL'

    cmTaskpaper = new CodeMirrorWidget({
        mode: 'text/plain'
        lineNumbers: true
        foldGutter:
            rangeFinder: CodeMirror.fold.indent
        gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter']
        tabSize: 4
    })
    cmTaskpaper.loadTarget('./todo.taskpaper')
    cmTaskpaper.title.text = 'Todo.taskpaper'

    cmSource = new CodeMirrorWidget({
        mode: 'text/coffeescript',
        lineNumbers: true,
        tabSize: 4,
    })
    cmSource.loadTarget('./index.coffee')
    cmSource.title.text = 'Source'

    cmCss = new CodeMirrorWidget({
        mode: 'text/css',
        lineNumbers: true,
        tabSize: 4,
    })
    cmCss.loadTarget('./index.css')
    cmCss.title.text = 'CSS'

    panel.insertLeft(cmTaskpaper)
    panel.insertTabAfter(cmSource, cmTaskpaper)
    panel.insertTabAfter(cmCss, cmSource)
    panel.insertBottom(coffeeconsole, cmTaskpaper)
    panel.attach(document.body)

    window.onresize = () -> panel.update()


window.onload = main
