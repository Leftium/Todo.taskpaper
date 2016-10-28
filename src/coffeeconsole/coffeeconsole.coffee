# PhosphorJS widget that hosts a CoffeeScript REPL.
#
# Part of Todo.taskpaper, an enhanced text editor for taskpaper files:
# https://github.com/Leftium/todo.taskpaper
#
# written by John-Kim Murphy
#
# Based on:
# - https://github.com/phosphorjs/phosphor-codemirror/blob/master/src/index.ts
# - https://github.com/larryng/coffeescript-repl/blob/master/coffee/main.coffee

import { Widget }   from 'phosphor-widget'
import { inspect }  from 'util'
import CoffeeScript from '../../lib/coffee-script.js'

import './coffeeconsole.css'

escapeHTML = (s) ->
    s.replace(/&/g,'&amp;')
     .replace(/</g,'&lt;')
     .replace(/>/g,'&gt;')

class CoffeeREPL
    DEFAULT_SETTINGS =
        lastVariable: '$_'
        maxLines: 500
        maxDepth: 2
        showHidden: false
        colorize: true

    constructor: (@output, @input, @prompt, settings={}) ->
        @history   = []
        @historyi  = -1
        @saved     = ''
        @multiline = false

        @settings = $.extend({}, DEFAULT_SETTINGS)

        if localStorage and localStorage.settings
          for k, v of JSON.parse(localStorage.settings)
            @settings[k] = v

        for k, v of settings
          @settings[k] = v

        @input.keydown @handleKeypress

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

                # Remove calling stack, which is usually not helpful.
                output = output.split('\n')[0]
            else
                output = e.toString()

        @saved = ''

        openSpan = (colorName) -> "<span class=ansi-#{colorName}>"

        ansi2tag =
            '1' : openSpan('bold')
            '3' : openSpan('italic')
            '4' : openSpan('underline')
            '7' : openSpan('inverse')
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
        @saved += if s[-1...] is '\\' then s[...-1] else s
        @saved += '\n'
        @addToHistory s

    clear: =>
        @output[0].innerHTML = ''
        undefined

    handleKeypress: (e) =>
        switch e.which
            when 13 # Enter
                e.preventDefault()
                input = @input.val()
                @input.val ''

                @print @prompt.html() + escapeHTML(input)

                if input
                    window.input = input
                    @addToSaved input
                    if input[-1...] isnt '\\' and not @multiline
                        @processSaved()

            when 27 # Esc
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

            when 38 # Up
                e.preventDefault()

                if @historyi < @history.length-1
                    @historyi += 1
                    @input.val @history[@historyi]

            when 40 # Down
                e.preventDefault()

                if @historyi > 0
                    @historyi += -1
                    @input.val @history[@historyi]

            when 76, 108  # L, l
                if e.ctrlKey
                    e.preventDefault()
                    @clear()

coffeeConsoleHtmlFragment = '''
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


export class CoffeeConsoleWidget extends Widget
    constructor: () ->
        super()
        @addClass('CoffeeConsoleWidget')

        @$node = $(@node)

        # construct div's here
        @$node.append(coffeeConsoleHtmlFragment)

        @SAVED_CONSOLE_LOG = console.log

        @$output    = $('.output',    @$node)
        @$input     = $('.input',     @$node)
        @$prompt    = $('.prompt',    @$node)
        @$inputdiv  = $('.inputdiv',  @$node)
        @$inputl    = $('.inputl',    @$node)
        @$inputr    = $('.inputr',    @$node)
        @$inputcopy = $('.inputcopy', @$node)

    onResize: (msg) =>
        super()
        @resizeInput()

    onAfterAttach: (msg) =>
        super()
        @init()
        @resizeInput()
        @$input.focus()

    resizeInput: (e) =>
        width = @$inputdiv.width() - @$inputl.width()
        content = @$input.val()
        content.replace /\n/g, '<br/>'
        @$inputcopy.html content

        @$inputcopy.width width
        @$input.width width
        @$input.height @$inputcopy.height() + 2


    scrollToBottom: () =>
        window.scrollTo 0, @$prompt[0].offsetTop


    init:() ->
        # bind other handlers
        @$input.keydown @scrollToBottom
        @$input.keyup @resizeInput
        @$input.change @resizeInput

        $('.container', @$node).click (e) =>
            if e.clientY > @$input[0].offsetTop
                @$input.focus()


        # instantiate our REPL
        @repl = new CoffeeREPL @$output, @$input, @$prompt

        # replace console.log
        console.log = (args...) =>
            @SAVED_CONSOLE_LOG.apply console, args
            @repl.print args...

        # expose repl as $$
        window.$$ = @repl

        # help
        window.help = =>
            @repl.print """

                <strong>Features</strong>
                <strong>========</strong>
                + <strong>Esc</strong> toggles multiline mode.
                + <strong>Up/Down arrow</strong> flips through line history.
                + <strong>#{$$.settings.lastVariable}</strong> stores the last returned value.
                + Access the internals of this console through <strong>$$</strong>.
                + <strong>$$.clear()</strong> clears this console.

                <strong>Settings</strong>
                <strong>========</strong>
                You can modify the behavior of this REPL by altering <strong>$$.settings</strong>:

                + <strong>lastVariable</strong> (#{@repl.settings.lastVariable}): variable name in which last returned value is stored
                + <strong>maxLines</strong> (#{@repl.settings.maxLines}): max line count of this console
                + <strong>maxDepth</strong> (#{@repl.settings.maxDepth}): max depth in which to inspect outputted object
                + <strong>showHidden</strong> (#{@repl.settings.showHidden}): flag to output hidden (not enumerable) properties of objects
                + <strong>colorize</strong> (#{@repl.settings.colorize}): flag to colorize output (set to false if REPL is slow)

                <strong>$$.saveSettings()</strong> will save settings to localStorage.
                <strong>$$.resetSettings()</strong> will reset settings to default.
                """

        # print header
        @repl.print """
          # CoffeeScript v#{CoffeeScript.VERSION} REPL
          # <a href="https://github.com/Leftium/todo.taskpaper" target="_blank">https://github.com/Leftium/todo.taskpaper</a>
          #
          # help() for features and tips.
          """

