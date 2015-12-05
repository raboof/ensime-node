net = require('net')
exec = require('child_process').exec
fs = require 'fs'
path = require('path')
_ = require 'lodash'

{Subscriber} = require 'emissary'
Client = require './client'
StatusbarView = require './views/statusbar-view'
{CompositeDisposable, TextEditor} = require 'atom'
{startClient} = require './ensime-startup'

ShowTypes = require './features/show-types'
Implicits = require './features/implicits'
AutoTypecheck = require './features/auto-typecheck'

TypeCheckingFeature = require './features/typechecking'
AutocompletePlusProvider = require './features/autocomplete-plus'
{log, modalMsg, isScalaSource, projectPath} = require './utils'

ImplicitInfo = require './model/implicit-info'
ImplicitInfoView = require './views/implicit-info-view'
SelectFile = require './views/select-file'
{parseDotEnsime} = require './ensime-client/dotensime-utils'

scalaSourceSelector = """atom-text-editor[data-grammar="source scala"]"""
InstanceManager = require './ensime-client/ensime-instance-manager'

module.exports = Ensime =

  config:
    ensimeServerVersion:
      description: 'Version of Ensime server',
      type: 'string',
      default: "0.9.10-SNAPSHOT",
      order: 1
    sbtExec:
      description: "Full path to sbt. 'which sbt'"
      type: 'string'
      default: ''
      order: 2
    ensimeServerFlags:
      description: 'java flags for ensime server startup'
      type: 'string'
      default: ''
      order: 3
    devMode:
      description: 'Turn on for extra console logging during development'
      type: 'boolean'
      default: false
      order: 4
    runServersDetached:
      description: "Run the Ensime servers as a detached processes. Useful while developing"
      type: 'boolean'
      default: false
      order: 5
    typecheckWhen:
      description: "When to typecheck"
      type: 'string'
      default: 'typing'
      enum: ['command', 'save', 'typing']
      order: 6
    enableTypeTooltip:
      description: "Enable tooltip that shows type when hovering"
      type: 'boolean'
      default: true
      order: 7
    markImplicitsAutomatically:
      description: "Mark implicits on buffer load and save"
      type: 'boolean'
      default: true
      order: 8
    noOfAutocompleteSuggestions:
      description: "Number of autocomplete suggestions requested of server"
      type: 'integer'
      default: 5
      order: 9



  addCommandsForStoppedState: ->
    # Need to have a started server and port file
    @stoppedCommands = new CompositeDisposable
    @stoppedCommands.add atom.commands.add 'atom-workspace', "ensime:update-ensime-server", -> updateEnsimeServer()
    @stoppedCommands.add atom.commands.add 'atom-workspace', "ensime:start", => @selectAndBootAnEnsime()


  addCommandsForStartedState: ->
    @startedCommands = new CompositeDisposable
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:stop", => @selectAndStopAnEnsime()
    @stoppedCommands.add atom.commands.add 'atom-workspace', "ensime:start", => @selectAndBootAnEnsime()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:mark-implicits", => @markImplicits()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:unmark-implicits", => @unmarkImplicits()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:show-implicits", => @showImplicits()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:typecheck-all", => @typecheckAll()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:unload-all", => @unloadAll()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:typecheck-file", => @typecheckFile()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:typecheck-buffer", => @typecheckBuffer()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:go-to-definition", => @goToDefinitionOfCursor()

    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:update-ensime-server", -> updateEnsimeServer()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:format-source", => @formatCurrentSourceFile()

    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:search-public-symbol", => @searchPublicSymbol()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:import-suggestion", => @getImportSuggestions()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:organize-imports", => @organizeImports()

  activate: (state) ->
    # Install deps if not there
    apd = require('atom-package-dependencies')
    apd.install()

    @subscriptions = new CompositeDisposable

    # Feature controllers
    @showTypesControllers = new WeakMap
    @implicitControllers = new WeakMap
    @autotypecheckControllers = new WeakMap

    @instanceManager = new InstanceManager

    @addCommandsForStoppedState()


    @controlSubscription = atom.workspace.observeTextEditors (editor) =>
      if isScalaSource(editor)
        # For now I'm doing least amount of change to support multiple ensime projects
        # This way you have to re-open editors after an ensime i started to get a client for it
        # client lookup could be pushed into the features so this is delayed
        clientLookup = => @instanceManager.instanceOfFile(editor.getPath())?.client
        if atom.config.get('Ensime.enableTypeTooltip')
          if not @showTypesControllers.get(editor) then @showTypesControllers.set(editor, new ShowTypes(editor, clientLookup))
        if not @implicitControllers.get(editor) then @implicitControllers.set(editor, new Implicits(editor, clientLookup))
        if not @autotypecheckControllers.get(editor) then @autotypecheckControllers.set(editor, new AutoTypecheck(editor, clientLookup))

        @subscriptions.add editor.onDidDestroy () =>
          @deleteControllers editor

    clientLookup = (editor) => @clientOfEditor(editor)
    @autocompletePlusProvider = new AutocompletePlusProvider(clientLookup)

    atom.workspace.onDidStopChangingActivePaneItem (pane) =>
      if(pane instanceof TextEditor and isScalaSource(pane))
        instance = @instanceManager.instanceOfFile(pane.getPath())
        @switchToInstance(instance)


  switchToInstance: (instance) ->
    console.log(['changed from ', @activeInstance, ' to ', instance])
    if(instance != @activeInstance)
      # TODO: create "class" for instance
      @activeInstance?.typechecking.hide()
      @activeInstance?.statusbarView.hide()
      @activeInstance = instance
      if(instance)
        instance.typechecking.show()
        instance.statusbarView.show()

  deactivate: ->
    @stopAllEnsimes()

  clientOfEditor: (editor) ->
    @instanceManager.instanceOfFile(editor.getPath())?.client

  clientOfActiveTextEditor: ->
    @clientOfEditor(atom.workspace.getActiveTextEditor())

  # TODO: move out
  statusbarOutput: (statusbarView, typechecking) -> (msg) ->
    typehint = msg.typehint

    if(typehint == 'AnalyzerReadyEvent')
      statusbarView.setText('Analyzer ready!')

    else if(typehint == 'FullTypeCheckCompleteEvent')
      statusbarView.setText('Full typecheck finished!')

    else if(typehint == 'IndexerReadyEvent')
      statusbarView.setText('Indexer ready!')

    else if(typehint == 'CompilerRestartedEvent')
      statusbarView.setText('Compiler restarted!')

    else if(typehint == 'ClearAllScalaNotesEvent')
      typechecking.clearScalaNotes()

    else if(typehint == 'NewScalaNotesEvent')
      typechecking.addScalaNotes(msg)

    else if(typehint.startsWith('SendBackgroundMessageEvent'))
      statusbarView.setText(msg.detail)



  initClient: (dotEnsimePath) ->

    # Register model-view mappings
    @subscriptions.add atom.views.addViewProvider ImplicitInfo, (implicitInfo) ->
      result = new ImplicitInfoView().initialize(implicitInfo)
      result


    # remove start command and add others
    @stoppedCommands.dispose()
    @addCommandsForStartedState()
    dotEnsime = parseDotEnsime(dotEnsimePath)

    typechecking = new TypeCheckingFeature()
    statusbarView = new StatusbarView()
    statusbarView.init()

    startClient(dotEnsime, @statusbarOutput(statusbarView, typechecking), (client) =>
      instance = {
        rootDir: dotEnsime.rootDir
        dotEnsime: dotEnsime
        client: client
        statusbarView: statusbarView
        typechecking: typechecking
      }

      @instanceManager.registerInstance(instance)
      if (not @activeInstance)
        @activeInstance = instance

      client.post({"typehint":"ConnectionInfoReq"}, (msg) -> )

      @switchToInstance(instance)
    )



  deleteControllers: (editor) ->
    deactivateAndDelete = (controller) ->
      controller.get(editor)?.deactivate()
      controller.delete(editor)

    deactivateAndDelete(@showTypesControllers)
    deactivateAndDelete(@implicitControllers)
    deactivateAndDelete(@autotypecheckControllers)


  deleteAllEditorsControllers: ->
    for editor in atom.workspace.getTextEditors()
      @deleteControllers editor


  # to start an ensime, first we need to to select a .ensime file under any project path
  selectAndBootAnEnsime: ->
    read = require('fs-readdir-recursive')

    dirs = atom.project.getPaths()
    # get all .ensimes with an ugly js-flatten:
    dotEnsimes = _.flatten(dirs.map((dir) ->
      filtered = read(dir, (f) -> f.endsWith ".ensime")
      filtered.map((f) -> dir + path.sep + f)
    ))

    console.log(['dotEnsime: ', dotEnsimes])

    new SelectFile(dotEnsimes, (selectedDotEnsime) =>
      console.log(['selectedDotEnsime: ', selectedDotEnsime])
      @initClient(selectedDotEnsime)
    )


  selectAndStopAnEnsime: ->
    # delet controllers of this ensime
    @deleteAllEditorsControllers()


  stopEnsime: ->


    @subscriptions.dispose()
    @controlSubscription.dispose()

    @autocompletePlusProvider?.dispose()
    @autocompletePlusProvider = null



  typecheckAll: ->
    @clientOfActiveTextEditor()?.post( {"typehint": "TypecheckAllReq"}, (msg) ->)

  unloadAll: ->
    @clientOfActiveTextEditor()?.post( {"typehint": "UnloadAllReq"}, (msg) ->)

  # typechecks currently open file
  typecheckBuffer: ->
    b = atom.workspace.getActiveTextEditor()?.getBuffer()
    @clientOfEditor(b)?.typecheckBuffer(b)

  typecheckFile: ->
    b = atom.workspace.getActiveTextEditor()?.getBuffer()
    @clientOfEditor(b)?.typecheckFile(b)

  goToDefinitionOfCursor: ->
    editor = atom.workspace.getActiveTextEditor()
    textBuffer = editor.getBuffer()
    pos = editor.getCursorBufferPosition()
    @clientOfEditor(editor)?.goToTypeAtPoint(textBuffer, pos)

  markImplicits: ->
    editor = atom.workspace.getActiveTextEditor()
    @implicitControllers.get(editor)?.showImplicits()

  unmarkImplicits: ->
    editor = atom.workspace.getActiveTextEditor()
    @implicitControllers.get(editor)?.clearMarkers()

  showImplicits: ->
    editor = atom.workspace.getActiveTextEditor()
    @implicitControllers.get(editor)?.showImplicitsAtCursor()


  provideAutocomplete: ->
    log('provideAutocomplete called')

    getProvider = =>
      @autocompletePlusProvider

    {
      selector: '.source.scala'
      disableForSelector: '.source.scala .comment'
      inclusionPriority: 10
      excludeLowerPriority: true

      getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        provider = getProvider()
        if(provider)
          new Promise (resolve) ->
            log('ensime.getSuggestions')
            provider.getCompletions(editor.getBuffer(), bufferPosition, resolve)
        else
          []
    }

  provideHyperclick: ->
    {
      providerName: 'ensime-atom'
      getSuggestionForWord: (textEditor, text, range) =>
        client = @clientOfEditor(textEditor)
        console.log("client " + client)
        {
          range: range
          callback: () ->
            if(client)
              client.goToTypeAtPoint(textEditor.getBuffer(), range.start)
            else
              atom.notifications.addError("Ensime not started! :(", {
                dismissable: true
                detail: "There is no running ensime instance for this particular file. Please start ensime first!"
                })
        }
    }


  formatCurrentSourceFile: ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPos = editor.getCursorBufferPosition()
    req =
      typehint: "FormatOneSourceReq"
      file:
        file: editor.getPath()
        contents: editor.getText()
    @clientOfEditor(editor)?.post(req, (msg) ->
      editor.setText(msg.text)
      editor.setCursorBufferPosition(cursorPos)
    )

  searchPublicSymbol: ->
    unless @publicSymbolSearch
      PublicSymbolSearch = require('./features/public-symbol-search')
      @publicSymbolSearch = new PublicSymbolSearch()
    @publicSymbolSearch.toggle(@clientOfActiveTextEditor())

  getImportSuggestions: ->
    unless @importSuggestions
      ImportSuggestions = require('./features/import-suggestions')
      @importSuggestions = new ImportSuggestions()
    editor = atom.workspace.getActiveTextEditor()
    @importSuggestions.getImportSuggestions(
      @clientOfEditor(editor),
      editor.getBuffer(),
      editor.getBuffer().characterIndexForPosition(editor.getCursorBufferPosition()),
      editor.getWordUnderCursor()
    )

  organizeImports: ->
    unless @refactorings
      Refactorings = require './features/refactorings'
      @refactorings = new Refactorings
    editor = atom.workspace.getActiveTextEditor()
    @refactorings.organizeImports(@clientOfEditor(editor), editor.getPath())
