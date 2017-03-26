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



spy.resolveCb = (data) ->
    window.d = data
    console.log 'Resolved'
    console.log data

spy.rejectCb = (error) ->
    window.e = error
    console.log 'Rejected'
    console.log error

import { textExtensions }            from './text-extensions.coffee'
import { welcomeTaskpaper }          from './welcome-taskpaper.coffee'

import { DockPanel }                 from 'phosphor-dockpanel'
import { CodeMirrorWidget }          from 'phosphor-codemirror'

import { CoffeeConsoleWidget }       from './coffeeconsole/coffeeconsole.coffee'
import { LinkViewWidget }            from './linkview/linkview.coffee'

import { amplify }                   from 'node-amplifyjs/lib/amplify.core.js'
import { parse as parseQueryString } from 'querystring'

import * as birch                    from 'birch-outline'

import CodeMirror                    from 'codemirror'
import * as Dbx                      from 'dropbox'
spy.Dbx = Dbx

import 'codemirror/mode/coffeescript/coffeescript'
import 'codemirror/mode/css/css'

import 'codemirror/addon/fold/foldcode.js'
import 'codemirror/addon/fold/indent-fold.js'
import 'codemirror/addon/fold/foldgutter.js'

import { DocState, Peer } from '../lib/ot_toy.js'

spy.DocState = DocState

import 'codemirror/addon/fold/foldgutter.css'
import 'codemirror/theme/solarized.css'
import './normalize.css'
import './index.css'


inceptionTour = "#!Welcome%20to%20Todo.taskpaper%20Inception!%0ALevel%201%3A%0A%09-%20Click%20me%3A%20https%3A%2F%2Fleftium.github.io%2FTodo.taskpaper%2F%23!Level%25202%253A%250A%2509-%2520Share%2520me%253A%2520the%2520link%2520in%2520the%2520address%2520bar%2520encodes%2520all%2520my%2520information!%250A%2509-%2520Proceed%2520to%2520Level%25203%253A%2520https%253A%252F%252Fleftium.github.io%252FTodo.taskpaper%252F%2523!Level%2525203%25253A%25250A%252509-%252520Edit%252520me%25253A%252520The%252520URL%252520changes%252520automatically%252520as%252520you%252520type%252509%25250A%252509-%252520Continue%252520to%252520level%2525204%25253A%252520https%25253A%25252F%25252Fleftium.github.io%25252FTodo.taskpaper%25252F%252523!Level%252525204%2525253A%2525250A%25252509-%25252520Please%25252520send%25252520feedback%25252520and%25252520comments%25252520to%25252520john%25252540leftium.com%25252520%25252509%2525250A%25252509-%25252520THE%25252520END!%2525250A%25250A%252509Where%252520did%252520this%252520page%252520come%252520from%25253F%25250A%250A%2509Nothing%2520is%2520stored%2520on%2520a%2520server!%250A%0A%09There%20is%20an%20entire%20document%20hidden%20inside%20that%20link...%0A"



`
    var pri = Math.floor(Math.random() * 0x1000000);
    var ser = 0;
    function getid() {
        return (pri * 0x100000) + ser++;
    }
    function diffToOps(diff, docState) {
        // console.log('diffToOps');
        var startTime = new Date()

        var start = diff[0];
        var end = diff[1];
        var newstr = diff[2];
        var result = [];
        for (var i = start; i < end; i++) {
            result.push({pri: pri, ty: 'del', ix: docState.xform_ix(i), id: getid()});
        }
        var ix = docState.xform_ix(end);
        for (var i = 0; i < newstr.length; i++) {
            result.push({pri: pri, ty: 'ins', ix: ix + i, id: getid(), ch: newstr.charAt(i)});
        }
        // console.log('diffToOps: ' + (new Date() - startTime))
        return result;
    }
    function getDiff(oldText, newText, cursor) {
        // console.log('getDiff');
        var startTime = new Date();

        var delta = newText.length - oldText.length;
        var limit = Math.max(0, cursor - delta);
        var end = oldText.length;
        while (end > limit && oldText.charAt(end - 1) == newText.charAt(end + delta - 1)) {
            end -= 1;
        }
        var start = 0;
        var startLimit = cursor - Math.max(0, delta);
        while (start < startLimit && oldText.charAt(start) == newText.charAt(start)) {
            start += 1;
        }
        // console.log('getDiff: ' + (new Date() - startTime))
        return [start, end, newText.slice(start, end + delta)];
    }
`

asynchronously = (method) =>
    setTimeout method, 0


#
# The main application entry point.
#
main = () ->
    class Sync
        constructor: () ->
            @id = 'Sync'
            @data = ''
            @docState = new DocState()
            @peer = new Peer()

            amplify.subscribe 'update', (ops) =>
                asynchronously () =>
                    rev = @docState.ops.length

                    @peer.merge_op(@docState, op) for op in ops
                    @onUpdate(@docState.get_str())

                    # not needed?
                    #
                    #if rev < @docState.ops.length
                    #    amplify.publish('update', ops.slice(rev))

        onUpdate: (newData) =>
            if newData isnt @data
                @data = newData
                true
            else
                false


        update: (newData, cursor=0) ->
            return
            asynchronously () =>
                diff = getDiff(@data, newData, cursor)
                ops = diffToOps(diff, @docState)

                # apply ops locally
                @docState.add(op) for op in ops

                @data = newData

                amplify.publish 'update', ops






    class SyncMaster
        constructor: () ->
            @data = ''
            @version = 0

        update: (data, source) =>
            source = source or this
            if source.version is @version and data isnt @data
                slog ['SyncMaster.update:', this, data is @data].concat(Array.from(arguments))
                @data = data
                @version++
                source.data = data
                source.version = @version
                # amplify.publish 'data-updated', source, @version, data

    syncMaster = new SyncMaster()

    class SyncView
        constructor: (syncMaster) ->
            @syncMaster = syncMaster
            @data = syncMaster.data
            @version = syncMaster.version

            amplify.subscribe 'data-updated', (source, version, data) =>
                @onDataUpdated(source, version, data)

        onDataUpdated: (source, version, data) ->
            if @version < version and @data isnt data
                slog ['SyncView.onDataUpdated:', this, ].concat(Array.from(arguments))
                @data = data
                @version = version
            else
                return false

    class HashView extends SyncView
        onDataUpdated: (source, version, data) ->
            if super(source, version, data)
                location.hash = '!' + encodeURIComponent(data)

    class DropboxView extends SyncView
        constructor: (syncMaster, path) ->
            super(syncMaster)
            @path = path
            @lastProcessingTime = new Date()

            spy.processDropbox = @processDropbox

            setInterval(@heartbeat, 100)
 
        onDataUpdated: (source, version, data) =>
            slog "DropboxView.onDataUpdated()"
            # @requestProcessing()
            @dirty = true

        heartbeat: () =>
            now = new Date()
            stale = (now - @lastProcessingTime) > (5 * 1000)
            if (@dirty or stale) and not @processing
                @lastProcessingTime = now
                processDropbox()

        processDropbox: () =>

            finishProcessing = (done) =>
                @processing = false
                if done
                    @dirty = false

            slog 'processDropbox'
            @startTime = new Date()

            # Check Dropbox for changes
            @processing = true
            promise1 = loadDropboxPath(@path)
            promise1.catch rejectCb
            promise1.then (data) =>
                slog.report = (title) =>
                    slog title
                    slog "Time:      ", (new Date() - @startTime)  / 1000
                    return
                    slog "syncView:  ", @version, @data
                    slog "syncMaster:", @syncMaster.version, @syncMaster.data
                    slog "Dropbox:   ", '0', data.text


                slog.report('BEFORE:')
                # Only changed on syncMaster
                if @data is data.text and @data isnt @syncMaster.data
                    slog "Update syncView and Dropbox. (Only changed on SyncMaster)"
                    @data = @syncMaster.data
                    @version = @syncMaster.version

                    # Update Dropbox
                    promise2 = dbx.filesUpload options =
                        path: path
                        contents: @data
                        mode:
                            '.tag': 'update'
                            update: data.rev
                    promise2.then (metaData) =>
                        data.text = @data
                        slog.report('AFTER:')

                        done = @data is @syncMaster.data and
                               @data is data.text and
                               @syncMaster.data is data.text

                        finishProcessing(done)

                # Only changed on Dropbox
                else if @data is @syncMaster.data and @data isnt data.text
                    slog "Update syncView and SyncMaster. (Only changed on Dropbox)"
                    @data = data.text
                    # Update syncMaster
                    @syncMaster.update(@data, this)

                    slog.report('AFTER:')
                    done = @data is @syncMaster.data and
                           @data is data.text and
                           @syncMaster.data is data.text

                    finishProcessing(done)

                else if @data isnt @syncMaster.data and @data isnt data.text
                    slog.report('CONFLICT!!\nAFTER:')
                    finishProcessing(true)
                else
                    slog.report('No changes.\nAFTER:')
                    finishProcessing(true)



    class DocView extends Sync
        constructor: (doc) ->
            super()
            @id += '.docview'
            @doc = doc
            @doc.setValue(@data)

            @doc.on 'changes', (cm, changes) =>
                for change,i in changes
                    slog.doc 'change', i
                    slog.doc 'from:   ', change.from
                    slog.doc 'to:     ', change.to
                    slog.doc 'text:   ', change.text
                    slog.doc 'origin: ', change.origin

                @update(@doc.getValue())

        onUpdate: (data) =>
            if super(data)
                @doc.setValue(@data)


    class OutlineView extends Sync
        constructor: (outline) ->
            super()
            @id += '.outlineview'
            @outline = outline

            outline.onDidEndChanges () =>
                @update(@outline.serialize())

        onUpdate: (data) =>
            if super(data)
                @outline.reloadSerialization(@data)




    class LinkView extends Sync
        constructor: (title='Link View', closable=true) ->
            super()
            @id += '.linkview'
            @widget = new LinkViewWidget()

            @widget.title.text = title
            @widget.title.closable = closable

        onUpdate: (data) =>
            if super(data)
                @widget.render(@data)

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

        doc = textView.editor
        expose.doc = doc
        docView = new DocView(doc)
        spy.dv = spy.docView = docView

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
        expose.outline = outline
        outlineView = new OutlineView(outline)

        panel = new DockPanel()
        panel.id = 'main'
        panel.attach(document.body)
        window.onresize = () -> panel.update()
        spy.panel = panel

        spy.coffeeConsole = makeConsole()
        linkView = new LinkView()
        spy.textView = makeTextView()

        spy.syncMaster = syncMaster
        spy.ov = spy.outlineView = outlineView
        spy.cc = spy.coffeeConsole = coffeeConsole
        spy.tv = spy.textView = textView
        spy.lv = spy.linkView = linkView


        panel.insertRight(textView)
        panel.insertBottom(coffeeConsole, textView)
        panel.insertLeft(linkView.widget)

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

    dbx = new Dbx.default
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

    makeAuthenticationUrl = (state) ->
        dbx.getAuthenticationUrl(location.href.split("#")[0], state)

    url = makeAuthenticationUrl(path)
    authenticationLink = "<a href='#{url}'>#{url}</a>"

    ensureDropboxToken = (state) =>
        authenticationUrl = makeAuthenticationUrl(state)

        promise = new Promise (resolve, reject) ->
            if not dbx.accessToken
                window.location = authenticationUrl
                reject(authenticationUrl)

            # test token with API call
            dbx.usersGetCurrentAccount()
                .then (accountData) ->
                    resolve(accountData)
                .catch (error) ->
                    delete localStorage.accessToken
                    window.location = authenticationUrl
                    reject(error)

    # User chose not to give access to Dropbox account
    dropboxAccessDenied = hashKeys.error is 'access_denied'
    if dropboxAccessDenied
        path = 'BLANK'
        log """

            ATTENTION: You chose not to give access to your Dropbox account.
            To give access later, just follow this link:
            #{authenticationLink}

            """


    openDropboxChooserLink =
        '<a onclick="dropboxChooser()" >Open Dropbox Chooser</a>'

    expose.dropboxChooser = () ->
        slog 'dropboxChooser'
        # Check access token first; this allows a smoother login flow UX
        # (Likely reduce login screens to one time instead of two)
        if dbx.accessToken
            Dropbox.choose options =
                extensions: textExtensions
                success: (files) ->
                    window.location.hash = files[0].link
        else
            window.location = makeAuthenticationUrl('CHOOSE')

    loadDropboxPath = (path) ->
        promise = new Promise (resolve, reject) ->

            options =
                path: path
            dropboxApiReady = not dropboxAccessDenied
            if dropboxApiReady
                p1 = dbx.filesGetMetadata options
                p1.then (metaData) =>
                    # source: http://stackoverflow.com/questions/190852
                    fileExtension = (fname) ->
                        fname.substr((~-fname.lastIndexOf(".") >>> 0) + 1)

                    if metaData['.tag'] is 'folder'
                        log "ERROR: #{path} is a folder. (Not supported)"
                        history.pushState(null, null, "#BLANK")
                        dropboxApiReady = false

                    extension = fileExtension(metaData.name).toLowerCase()
                    if extension not in textExtensions
                        log "ERROR: File #{path} is not a text file (based on file extension)."
                        history.pushState(null, null, "#BLANK")
                        dropboxApiReady = false
                        spy.name = metaData.name

                    if dropboxApiReady
                        p2 = dbx.filesDownload options

                        p2.then (fileData) =>
                            reader = new FileReader()

                            reader.addEventListener 'loadend', () ->
                                # reader.result contains the contents of blob as a typed array
                                stringResult = new TextDecoder('utf8').decode(reader.result)

                                data =
                                    text: stringResult
                                    rev: metaData.rev

                                resolve(data)

                            reader.readAsArrayBuffer(fileData.fileBlob)

                p1.catch (error) =>
                    slog error
                    spy.error = error
                    switch error.status
                        when 409  # Path not found
                            log "ERROR: File #{path} not found on Dropbox."
                            history.pushState(null, null, "#BLANK")
                        else
                            ensureDropboxToken(path).then () ->
                                log "ERROR: #{error.error} (Status: #{error.status})"
                                history.pushState(null, null, "#BLANK")

    if path is '/' or path is ''
        path = 'WELCOME'
    history.pushState(null, null, "##{path}")

    exposeVariables = () =>

        expose.amplify = amplify

        spy.parseQueryString = parseQueryString
        spy.ensureDropboxToken = ensureDropboxToken

        spy.hashKeys = hashKeys
        spy.path = path
        spy.dbx = dbx
        spy.dropboxAccessDenied = dropboxAccessDenied

    loadShebang = (string) ->
        hashView = new HashView(syncMaster)
        syncMaster.update(decodeURIComponent(string))
        amplify.publish 'outline-ready'
        spy.hashView = hashView
        exposeVariables()
        return

    initPanel()
    if path[0] is '!'
        loadShebang(path[1...])
        return


    switch path
        when 'WELCOME'
            loadShebang(welcomeTaskpaper)
        when 'BLANK', 'NEW', 'DEMO'
            loadShebang('')
        when 'INCEPTION'
            loadShebang(inceptionTour)
        when 'CHOOSE'
            try
                dropboxChooser()
            catch e
                log """
                    ATTENTION: Dropbox chooser was blocked by the browser.
                    Click this link to launch manually:
                    #{openDropboxChooserLink}

                    """
        else  # Dropbox
            afterDropbox = (path) ->
                promise = loadDropboxPath(path)
                promise.then (data) ->
                    doc.setValue(data.text)
                    dropboxView = new DropboxView(syncMaster, path)
                    dropboxView.data = data.text
                    dropboxView.rev = data.rev

                    spy.dropboxView = dropboxView

                promise.catch (error) ->
                    slog 'ERROR'

            # Shared link
            if ///^https?://www.dropbox.com/s///.test(path)
                p1 = dbx.sharingGetSharedLinkFile options =
                    url: path
                p1.then (fileData) ->
                    window.supressReload = true
                    window.location.hash = fileData.path_lower
                    afterDropbox(fileData.path_lower)
                p1.catch (error) ->
                    slog 'Error @sharingGetSharedLinkFile'
                    slog error
                    ensureDropboxToken(path).then () ->
                        log "ERROR: #{error.error} (Status: #{error.status})"
                        history.pushState(null, null, "#BLANK")
            else
                afterDropbox(path)


    exposeVariables()







window.onload = main

window.onhashchange = (e) ->
    slog "onhashchange: #{location.hash}"
    slog "newURL: #{e.newURL}"
    slog "oldURL: #{e.oldURL}"

    reload = false

    reloadWhiteList = ///
        ^WELCOME$
       |^NEW$
       |^DEMO$
       |^BLANK$
       |^INCEPTION$
       |^CHOOSE$
       |^/
       |^http
    ///i



    hash = location.hash[1...]
    reload ||= reloadWhiteList.test(hash)

    if reload and not window.supressReload
        # slog "loading: #{e.newURL}"
        slog "supressReload", window.supressReload
        window.location.reload()
    else
        # slog "skipping: #{e.newURL}"
        window.supressReload = false


