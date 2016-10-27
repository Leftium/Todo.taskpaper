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
import './coffeeconsole.css'

import CoffeeScript from './coffee-script.js'
import { inspect } from 'util'


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

class CoffeeConsoleWidget extends Widget
    constructor: () ->
        super()
        @addClass('CoffeeConsoleWidget')

        $node = $(@node)

        # construct div's here
        htmlFragment = '''
            <div class="container">
              <div class="outputdiv">
                <pre class="output"></pre>
              </div>
              <div class="inputdiv">
                <div class="inputl">
                  <pre class="prompt">coffee&gt;&nbsp;</pre>
                </div>
                <div class="inputr">
                  <textarea class="input" spellcheck="false"></textarea>
                  <div class="inputcopy"></div>
                </div>
              </div>
            </div>'''
        $node.append(htmlFragment)

        SAVED_CONSOLE_LOG = console.log

        $output    = $('.output',    $node)
        $input     = $('.input',     $node)
        $prompt    = $('.prompt',    $node)
        $inputdiv  = $('.inputdiv',  $node)
        $inputl    = $('.inputl',    $node)
        $inputr    = $('.inputr',    $node)
        $inputcopy = $('.inputcopy', $node)

        escapeHTML = (s) ->
          s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');


        class CoffeeREPL
          DEFAULT_SETTINGS =
            lastVariable: '$_'
            maxLines: 500
            maxDepth: 2
            showHidden: false
            colorize: true

          constructor: (@output, @input, @prompt, settings={}) ->
            @history = []
            @historyi = -1
            @saved = ''
            @multiline = false

            @settings = $.extend({}, DEFAULT_SETTINGS)

            if localStorage and localStorage.settings
              for k, v of JSON.parse(localStorage.settings)
                @settings[k] = v

            for k, v of settings
              @settings[k] = v

            @input.keydown @handleKeypress

            window.input = @input

          resetSettings: ->
            localStorage.clear()

          saveSettings: ->
            localStorage.settings = JSON.stringify($.extend({}, @settings))

          print: (args...) =>
            s = args.join(' ') or ' '
            o = @output[0].innerHTML + s + '\n'
            @output[0].innerHTML = o.split('\n')[-@settings.maxLines...].join('\n')
            undefined

          processSaved: =>
            try
              compiled = CoffeeScript.compile @saved
              compiled = compiled[14...-17]
              value = eval.call window, compiled
              window[@settings.lastVariable] = value
              output = inspect value, @settings.showHidden, @settings.maxDepth, @settings.colorize
            catch e
              if e.stack
                output = e.stack

                # FF doesn't have Error.toString() as the first line of Error.stack
                # while Chrome does.
                if output.split('\n')[0] isnt e.toString()
                  output = "#{e.toString()}\n#{e.stack}"
              else
                output = e.toString()
            @saved = ''

            ansiEscape = /\u001b\[(\d{1,2})m/g
            window.ansiEscape = ansiEscape

            escapeCode = (num) -> "\u001b[#{num}m"
            openSpan = (colorName) -> "<span class=ansi-#{colorName}>"

            ansi2tag =
                '1': openSpan('bold')
                '3': openSpan('italic')
                '4': openSpan('underline')
                '7': openSpan('inverse')
                '37': openSpan('white')
                '90': openSpan('grey')
                '30': openSpan('black')
                '34': openSpan('blue')
                '36': openSpan('cyan')
                '32': openSpan('green')
                '35': openSpan('magenta')
                '31': openSpan('red')
                '33': openSpan('yellow')
                '22': '</span>'
                '23': '</span>'
                '24': '</span>'
                '27': '</span>'
                '39': '</span>'

            for key,value of ansi2tag
                output = output.replace(///\u001b\[#{key}m///g, value)

            @print output

          setPrompt: =>
            s = if @multiline then '------' else 'coffee'
            @prompt.html "#{s}&gt;&nbsp;"

          addToHistory: (s) =>
            @history.unshift s
            @historyi = -1

          addToSaved: (s) =>
            @saved += if s[...-1] is '\\' then s[0...-1] else s
            @saved += '\n'
            @addToHistory s

          clear: =>
            @output[0].innerHTML = ''
            undefined

          handleKeypress: (e) =>
            switch e.which
              when 13
                e.preventDefault()
                input = @input.val()
                @input.val ''

                @print @prompt.html() + escapeHTML(input)

                if input
                  @addToSaved input
                  if input[...-1] isnt '\\' and not @multiline
                    @processSaved()

              when 27
                e.preventDefault()
                input = @input.val()

                if input and @multiline and @saved
                  input = @input.val()
                  @input.val ''

                  @print @prompt.html() + escapeHTML(input)
                  @addToSaved input
                  @processSaved()
                else if @multiline and @saved
                  @processSaved()

                @multiline = not @multiline
                @setPrompt()

              when 38
                e.preventDefault()

                if @historyi < @history.length-1
                  @historyi += 1
                  @input.val @history[@historyi]

              when 40
                e.preventDefault()

                if @historyi > 0
                  @historyi += -1
                  @input.val @history[@historyi]


        resizeInput = (e) ->
          width = $inputdiv.width() - $inputl.width()
          content = $input.val()
          content.replace /\n/g, '<br/>'
          $inputcopy.html content

          $inputcopy.width width
          $input.width width
          $input.height $inputcopy.height() + 2


        scrollToBottom = ->
          window.scrollTo 0, $prompt[0].offsetTop


        init = ->

          # bind other handlers
          $input.keydown scrollToBottom

          $(window).resize resizeInput
          $input.keyup resizeInput
          $input.change resizeInput

          
          $('.container', $node).click (e) ->
            if e.clientY > $input[0].offsetTop
              $input.focus()
          

          # instantiate our REPL
          repl = new CoffeeREPL $output, $input, $prompt

          # replace console.log
          console.log = (args...) ->
            SAVED_CONSOLE_LOG.apply console, args
            repl.print args...

          # expose repl as $$
          window.$$ = repl

          # initialize window
          resizeInput()
          $input.focus()

          # help
          window.help = ->
            text = [
              " "
              "<strong>Features</strong>"
              "<strong>========</strong>"
              "+ <strong>Esc</strong> toggles multiline mode."
              "+ <strong>Up/Down arrow</strong> flips through line history."
              "+ <strong>#{repl.settings.lastVariable}</strong> stores the last returned value."
              "+ Access the internals of this console through <strong>$$</strong>."
              "+ <strong>$$.clear()</strong> clears this console."
              " "
              "<strong>Settings</strong>"
              "<strong>========</strong>"
              "You can modify the behavior of this REPL by altering <strong>$$.settings</strong>:"
              " "
              "+ <strong>lastVariable</strong> (#{repl.settings.lastVariable}): variable name in which last returned value is stored"
              "+ <strong>maxLines</strong> (#{repl.settings.maxLines}): max line count of this console"
              "+ <strong>maxDepth</strong> (#{repl.settings.maxDepth}): max depth in which to inspect outputted object"
              "+ <strong>showHidden</strong> (#{repl.settings.showHidden}): flag to output hidden (not enumerable) properties of objects"
              "+ <strong>colorize</strong> (#{repl.settings.colorize}): flag to colorize output (set to false if REPL is slow)"
              " "
              "<strong>$$.saveSettings()</strong> will save settings to localStorage."
              "<strong>$$.resetSettings()</strong> will reset settings to default."
              " "
            ].join('\n')
            repl.print text

          # print header
          repl.print [
            "# CoffeeScript v#{CoffeeScript.VERSION} REPL"
            "# <a href=\"https://github.com/larryng/coffeescript-repl\" target=\"_blank\">https://github.com/larryng/coffeescript-repl</a>"
            "#"
            "# help() for features and tips."
            " "
          ].join('\n')


        init()

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
