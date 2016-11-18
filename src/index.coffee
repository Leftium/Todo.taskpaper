# Based on http://phosphorjs.github.io/examples/dockpanel/

# To explicitly expose variables. (Acessible from the CoffeeConsole.)
expose = window

# To temporarily introspect variables during development.
spy = window
slog = console.log # spy + log

spy.resolveCb = (data) ->
    window.d = data
    console.log 'Resolved'
    console.log data

spy.rejectCb = (error) ->
    window.e = error
    console.log 'Rejected'
    console.log error

import { textExtensions }            from './text-extensions.coffee'

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
    class SyncMaster
        constructor: () ->
            @data = ''
            @version = 0

        update: (source, data) ->
            if source.version is @version and data isnt @data
                slog ['SyncMaster.update:', this, data is @data].concat(Array.from(arguments))
                @data = data
                @version++
                source.data = data
                source.version = @version
                amplify.publish 'data-updated', source, @version, data

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
                    slog "syncView:  ", @version, @data
                    slog "syncMaster:", @syncMaster.version, @syncMaster.data
                    slog "Dropbox:   ", '0', data.text
                    slog "Time:      ", (new Date() - @startTime)  / 1000

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
                    @syncMaster.update(this, @data)

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



    class DocView extends SyncView
        constructor: (syncMaster, doc) ->
            super(syncMaster)
            @doc = doc
            @doc.setValue(@data)

            @doc.on 'change', () =>
                @syncMaster.update(this, @doc.getValue())


        onDataUpdated: (source, version, data) =>
            if super(source, version, data)
                @doc.setValue(@data)


    class OutlineView extends SyncView
        constructor: (syncMaster, outline) ->
            super(syncMaster)
            @outline = outline

            outline.onDidEndChanges () =>
                @syncMaster.update(this, @outline.serialize())


        onDataUpdated: (source, version, data) =>
            if super(source, version, data)
                @outline.reloadSerialization(@data)


    panel = new DockPanel()
    panel.id = 'main'

    coffeeconsole = new CoffeeConsoleWidget()
    coffeeconsole.title.text = 'CoffeeScript REPL'

    linkView = new LinkViewWidget(syncMaster)
    linkView.title.text = 'Link View'

    spy.linkView = linkView


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
    docView = new DocView(syncMaster, doc)

    # Initialize outline
    outline = new birch.Outline.createTaskPaperOutline(syncMaster.data)
    outlineView = new OutlineView(syncMaster, outline)


    spy.syncMaster = syncMaster
    spy.docView = docView
    spy.outlineView = outlineView


    cmTaskpaper.title.text = 'CodeMirror View'
    panel.insertRight(cmTaskpaper)
    panel.insertRight(linkView)
    panel.insertBottom(coffeeconsole, cmTaskpaper)
    panel.attach(document.body)

    window.onresize = () -> panel.update()

    loadDefault = () ->
        cmTaskpaper.loadTarget './welcome.taskpaper', () ->
            contents = doc.getValue()

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
        '<a onclick="launchDropBoxChooser()" >Open Dropbox Chooser</a>'

    expose.launchDropBoxChooser = () ->
        slog 'launchDropBoxChooser'
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

    switch path
        when 'WELCOME'
            loadDefault()
            amplify.publish 'outline-ready'
        when 'BLANK', 'NEW', 'DEMO'
            amplify.publish 'outline-ready'
        when 'CHOOSE'
            try
                launchDropBoxChooser()
            catch e
                log """
                    ATTENTION: Dropbox chooser was blocked by the browser.
                    Click this link to launch manually:
                    #{openDropboxChooserLink}

                    """
        else  # Dropbox
            # Shared link
            if ///^https?://www.dropbox.com/s///.test(path)
                p1 = dbx.sharingGetSharedLinkFile options =
                    url: path
                p1.then (fileData) ->
                    window.location.hash = fileData.path_lower
                p1.catch (error) ->
                    slog 'Error @sharingGetSharedLinkFile'
                    slog error
                    ensureDropboxToken(path).then () ->
                        log "ERROR: #{error.error} (Status: #{error.status})"
                        history.pushState(null, null, "#BLANK")
            else
                promise = loadDropboxPath(path)
                promise.then (data) ->
                    doc.setValue(data.text)
                    dropboxView = new DropboxView(syncMaster, path)
                    dropboxView.data = data.text
                    dropboxView.rev = data.rev

                    spy.dropboxView = dropboxView
                promise.catch (error) ->
                    slog 'ERROR'






    expose.doc = doc
    expose.outline = outline

    expose.amplify = amplify

    spy.parseQueryString = parseQueryString
    spy.ensureDropboxToken = ensureDropboxToken

    spy.coffeeconsole = coffeeconsole
    spy.hashKeys = hashKeys
    spy.path = path
    spy.dbx = dbx
    spy.dropboxAccessDenied = dropboxAccessDenied

window.onload = main

window.onhashchange = () ->
    slog "onhashchange: #{location.hash}"
    if window.changeOnlyHash
        slog 'skip reload'
    else
        slog 'reloading...'
        window.location.reload()


