net = require('net')
exec = require('child_process').exec
fs = require 'fs'
path = require('path')
_ = require 'lodash'
Promise = require 'bluebird'
glob = require 'glob'

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
{modalMsg, isScalaSource, projectPath} = require './utils'

ImplicitInfo = require './model/implicit-info'
ImplicitInfoView = require './views/implicit-info-view'
SelectDotEnsimeView = require './views/select-dot-ensime-view'
{parseDotEnsime, dotEnsimesFilter} = require './ensime-client/dotensime-utils'

InstanceManager = require './ensime-client/ensime-instance-manager'
Instance = require './ensime-client/ensime-instance'

log = require('loglevel')


scalaSourceSelector = """atom-text-editor[data-grammar="source scala"]"""
module.exports = Ensime =

  config:
    ensimeServerVersion:
      description: 'Version of Ensime server',
      type: 'string',
      default: "0.9.10-SNAPSHOT",
      order: 10
    sbtExec:
      description: "Full path to sbt. 'which sbt'"
      type: 'string'
      default: ''
      order: 20
    useCoursierToBootstrapServer:
      description: "User Coursier for bootstrapping server (experimental)'"
      type: 'boolean'
      default: false
      order: 30
    ensimeServerFlags:
      description: 'java flags for ensime server startup'
      type: 'string'
      default: ''
      order: 40
    logLevel:
      description: 'Console log level. Turn up for troubleshooting'
      type: 'string'
      default: 'trace'
      enum: ['trace', 'debug', 'info', 'warn', 'error']
      order: 50
    runServersDetached:
      description: "Run the Ensime servers as a detached processes. Useful while developing"
      type: 'boolean'
      default: false
      order: 60
    typecheckWhen:
      description: "When to typecheck"
      type: 'string'
      default: 'typing'
      enum: ['command', 'save', 'typing']
      order: 70
    enableTypeTooltip:
      description: "Enable tooltip that shows type when hovering"
      type: 'boolean'
      default: true
      order: 80
    richTypeTooltip:
      description: "Use rich type tooltip with hrefs"
      type: 'boolean'
      default: true
      order: 90
    markImplicitsAutomatically:
      description: "Mark implicits on buffer load and save"
      type: 'boolean'
      default: true
      order: 100
    noOfAutocompleteSuggestions:
      description: "Number of autocomplete suggestions requested of server"
      type: 'integer'
      default: 10
      order: 110
    documentationSplit:
      description: "Where to open ScalaDoc"
      type: 'string'
      default: 'right'
      enum: ['right', 'external-browser']
      order: 120
    enableAutoInstallOfDependencies:
      description: "Enable auto install of dependencies"
      type: boolean
      default: true
      order: 130

  addCommandsForStoppedState: ->
    @stoppedCommands = new CompositeDisposable
    @stoppedCommands.add atom.commands.add 'atom-workspace', "ensime:start", => @selectAndBootAnEnsime()

  addCommandsForStartedState: ->
    @startedCommands = new CompositeDisposable
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:stop", => @selectAndStopAnEnsime()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:start", => @selectAndBootAnEnsime()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:mark-implicits", => @markImplicits()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:unmark-implicits", => @unmarkImplicits()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:show-implicits", => @showImplicits()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:typecheck-all", => @typecheckAll()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:unload-all", => @unloadAll()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:typecheck-file", => @typecheckFile()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:typecheck-buffer", => @typecheckBuffer()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:go-to-definition", => @goToDefinitionOfCursor()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:go-to-doc", => @goToDocOfCursor()
    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:browse-doc", => @goToDocIndex()

    @startedCommands.add atom.commands.add scalaSourceSelector, "ensime:format-source", => @formatCurrentSourceFile()

    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:search-public-symbol", => @searchPublicSymbol()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:import-suggestion", => @getImportSuggestions()
    @startedCommands.add atom.commands.add 'atom-workspace', "ensime:organize-imports", => @organizeImports()

    

  activate: (state) ->
    logLevel = atom.config.get('Ensime.logLevel')
    
    log.getLogger('ensime.client').setLevel(logLevel)
    log.getLogger('ensime.server-update').setLevel(logLevel)
    log.getLogger('ensime.startup').setLevel(logLevel)
    log.getLogger('ensime.autocomplete-plus-provider').setLevel(logLevel)
    log.getLogger('ensime.refactorings').setLevel(logLevel)
    log = log.getLogger('ensime.main')
    log.setLevel(logLevel)
    
    # Install deps if not there
    if(atom.config.get('Ensime.eenableAutoInstallOfDependencies')
      (require 'atom-package-deps').install('Ensime').then ->
        log.trace('Ensime dependencies installed, good to go!')

    @subscriptions = new CompositeDisposable

    # Feature controllers
    @showTypesControllers = new WeakMap
    @implicitControllers = new WeakMap
    @autotypecheckControllers = new WeakMap

    @instanceManager = new InstanceManager

    @addCommandsForStoppedState()
    @someInstanceStarted = false
    
    @controlSubscription = atom.workspace.observeTextEditors (editor) =>
      if isScalaSource(editor)
        instanceLookup = => @instanceManager.instanceOfFile(editor.getPath())
        clientLookup = -> instanceLookup()?.client
        if atom.config.get('Ensime.enableTypeTooltip')
          if not @showTypesControllers.get(editor) then @showTypesControllers.set(editor, new ShowTypes(editor, clientLookup))
        if not @implicitControllers.get(editor) then @implicitControllers.set(editor, new Implicits(editor, instanceLookup))
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
    log.trace(['changed from ', @activeInstance, ' to ', instance])
    if(instance != @activeInstance)
      # TODO: create "class" for instance
      @activeInstance?.statusbarView.hide()
      @activeInstance = instance
      if(instance)
        instance.statusbarView.show()

    
  deactivate: ->
    @instanceManager.destroyAll()

    @subscriptions.dispose()
    @controlSubscription.dispose()

    @autocompletePlusProvider?.dispose()
    @autocompletePlusProvider = null


  clientOfEditor: (editor) ->
    if(editor)
      @instanceManager.instanceOfFile(editor.getPath())?.client
    else
      @instanceManager.firstInstance().client

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
      typechecking?.clearScalaNotes()

    else if(typehint == 'NewScalaNotesEvent')
      typechecking?.addScalaNotes(msg)

    else if(typehint.startsWith('SendBackgroundMessageEvent'))
      statusbarView.setText(msg.detail)



  startInstance: (dotEnsimePath) ->

    # Register model-view mappings
    @subscriptions.add atom.views.addViewProvider ImplicitInfo, (implicitInfo) ->
      result = new ImplicitInfoView().initialize(implicitInfo)
      result


    # remove start command and add others
    @stoppedCommands.dispose()
    
    # FIXME: - we have had double commands for each instance :) This is a quick and dirty fix
    if(not @someInstanceStarted)
      @addCommandsForStartedState()
      @someInstanceStarted = true
      
    dotEnsime = parseDotEnsime(dotEnsimePath)

    typechecking = undefined
    if(@indieLinterRegistry)
      typechecking = TypeCheckingFeature(@indieLinterRegistry.register("Ensime: #{dotEnsimePath}"))
    
    statusbarView = new StatusbarView()
    statusbarView.init()

    startClient(dotEnsime, @statusbarOutput(statusbarView, typechecking), (client) =>
      instance = Instance(dotEnsime, client, statusbarView, typechecking)

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

  # Shows dialog to select a .ensime under this project paths and calls callback with parsed
  selectDotEnsime: (callback, filter = -> true) ->
    dirs = atom.project.getPaths()
    globTask = Promise.promisify(glob)
    promises = dirs.map (dir) ->
      globTask(
        '.ensime'
          cwd: dir
          matchBase: true
          nodir: true
          realpath: true
          ignore: '**/{node_modules,.ensime_cache,.git,target,.idea}/**'
      )

    promise = Promise.all(promises)

    promise.then (dotEnsimesUnflattened) ->
      dotEnsimes = ({path: path} for path in _.flattenDeep(dotEnsimesUnflattened))
      filteredDotEnsime = _.filter(dotEnsimes, filter)
      
      if(filteredDotEnsime.length == 0)
        modalMsg("No .ensime file found. Please generate with `sbt gen-ensime` or similar")
      else if (filteredDotEnsime.length == 1)
        callback(filteredDotEnsime[0])
      else
        new SelectDotEnsimeView(filteredDotEnsime, (selectedDotEnsime) ->
          callback(selectedDotEnsime)
        )

  selectAndBootAnEnsime: ->
    @selectDotEnsime(
      (selectedDotEnsime) => @startInstance(selectedDotEnsime.path),
      (dotEnsime) => not @instanceManager.isStarted(dotEnsime.path)
    )


  selectAndStopAnEnsime: ->
    stopDotEnsime = (selectedDotEnsime) =>
      dotEnsime = parseDotEnsime(selectedDotEnsime.path)
      @instanceManager.stopInstance(dotEnsime)
      @switchToInstance(undefined)

    @selectDotEnsime(stopDotEnsime, (dotEnsime) => @instanceManager.isStarted(dotEnsime.path))

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

  goToDocOfCursor: ->
    editor = atom.workspace.getActiveTextEditor()
    @clientOfEditor(editor)?.goToDocAtPoint(editor)

  goToDocIndex: ->
    editor = atom.workspace.getActiveTextEditor()
    @clientOfEditor(editor)?.goToDocIndex()

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
    log.trace('provideAutocomplete called')

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
            log.trace('ensime.getSuggestions')
            provider.getCompletions(editor.getBuffer(), bufferPosition, resolve)
        else
          []
          
      onDidInsertSuggestion: (x) ->
        provider = getProvider()
        provider.onDidInsertSuggestion x
    }

  provideHyperclick: ->
    {
      providerName: 'ensime-atom'
      getSuggestionForWord: (textEditor, text, range) =>
        if isScalaSource(textEditor)
          client = @clientOfEditor(textEditor)
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
        else
          undefined

    }
    
  # Just add registry to delegate registration on instances
  consumeLinter: (@indieLinterRegistry) ->
    
    
  formatCurrentSourceFile: ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPos = editor.getCursorBufferPosition()
    callback = (msg) ->
      editor.setText(msg.text)
      editor.setCursorBufferPosition(cursorPos)
    @clientOfEditor(editor)?.formatSourceFile(editor.getPath(), editor.getText(), callback)
    

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
