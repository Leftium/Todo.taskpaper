# Based on http://phosphorjs.github.io/examples/dockpanel/

import { DockPanel } from 'phosphor-dockpanel'
import { Message } from 'phosphor-messaging'
import { ResizeMessage, Widget } from 'phosphor-widget'

import './index.css'

#
# A widget which hosts a CodeMirror editor.
#
class CodeMirrorWidget extends Widget
  constructor: (config) ->
    super()
    @addClass('CodeMirrorWidget')
    @_editor = CodeMirror(@node, config)

  loadTarget: (target) ->
    doc = @_editor.getDoc()
    xhr = new XMLHttpRequest()
    xhr.open('GET', target)
    xhr.onreadystatechange = () -> doc.setValue(xhr.responseText)
    xhr.send()

  onAfterAttach: (msg) ->
    @_editor.refresh()

  onResize: (msg) ->
    if msg.width < 0 or msg.height < 0
      @_editor.refresh()
    else
      @_editor.setSize(msg.width, msg.height)

  _editor: CodeMirror.Editor



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
