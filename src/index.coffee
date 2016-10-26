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

  cmSource = new CodeMirrorWidget({
    mode: 'text/typescript',
    lineNumbers: true,
    tabSize: 2,
  })
  cmSource.loadTarget('./index.ts')
  cmSource.title.text = 'Source'

  cmCss = new CodeMirrorWidget({
    mode: 'text/css',
    lineNumbers: true,
    tabSize: 2,
  })
  cmCss.loadTarget('./index.css')
  cmCss.title.text = 'CSS'

  panel.insertLeft(cmSource)
  panel.insertTabAfter(cmCss, cmSource)
  panel.insertBottom(b1, cmSource)
  panel.attach(document.body)

  window.onresize = () -> panel.update()


window.onload = main
