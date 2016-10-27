# Based on http://phosphorjs.github.io/examples/dockpanel/

import { DockPanel } from 'phosphor-dockpanel'
import { CodeMirrorWidget } from 'phosphor-codemirror'
import { Message } from 'phosphor-messaging'
import { ResizeMessage, Widget } from 'phosphor-widget'

import CodeMirror from 'codemirror'

import 'codemirror/mode/coffeescript/coffeescript'
import 'codemirror/mode/css/css'
import 'codemirror/addon/fold/foldcode.js'
import 'codemirror/addon/fold/foldgutter.js'
import 'codemirror/addon/fold/indent-fold.js'

import 'codemirror/lib/codemirror.css'
import 'codemirror/addon/fold/foldgutter.css'
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
# Create a placeholder content widget.
#
createContent = (title) ->
  widget = new Widget()
  widget.addClass('content')
  widget.addClass(title.toLowerCase())

  widget.title.text = title
  widget.title.closable = true

  widget


#
# The main application entry point.
#
main = () ->
  panel = new DockPanel()
  panel.id = 'main'

  b1 = createContent('Blue')

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
  panel.insertBottom(b1, cmTaskpaper)
  panel.attach(document.body)

  window.onresize = () -> panel.update()


window.onload = main
