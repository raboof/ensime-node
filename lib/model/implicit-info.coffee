{Emitter, CompositeDisposable} = require 'atom'

module.exports = class ImplicitInfo
  constructor: (@infos, @editor, pos) ->
    @active = false

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor.ensime-implicits-active',
      'ensime:applyImplicit': @confirmSelection,
      'core:cancel': @cancel

    @overlayMarker = @editor.markBufferPosition(pos)
    overlayDecoration = @editor.decorateMarker(@overlayMarker, {type: 'overlay', item: this, position: 'head'})

  bindToMovementCommands: ->
    commandNamespace = 'core' # This was an option in autocomplete-plus

    commands = {}
    commands["#{commandNamespace}:move-up"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectPrevious()
        event.stopImmediatePropagation()
    commands["#{commandNamespace}:move-down"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectNext()
        event.stopImmediatePropagation()
    commands["#{commandNamespace}:page-up"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectPageUp()
        event.stopImmediatePropagation()
    commands["#{commandNamespace}:page-down"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectPageDown()
        event.stopImmediatePropagation()
    commands["#{commandNamespace}:move-to-top"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectTop()
        event.stopImmediatePropagation()
    commands["#{commandNamespace}:move-to-bottom"] = (event) =>
      if @isActive() and @items?.length > 1
        @selectBottom()
        event.stopImmediatePropagation()

    @movementCommandSubscriptions?.dispose()
    @movementCommandSubscriptions = new CompositeDisposable
    @movementCommandSubscriptions.add atom.commands.add('atom-text-editor.ensime-implicits-active', commands)


  activate: ->
    @addKeyboardInteraction()
    @active = true

  cancel: =>
    @emitter.emit('did-cancel')
    @dispose()

  onDidCancel: (fn) ->
    @emitter.on('did-cancel', fn)

  
  onDidDispose: (fn) ->
    @emitter.on('did-dispose', fn)

  confirmSelection: =>
    @emitter.emit('did-confirm')

  onDidConfirmSelection: =>
    @emitter.on('did-confirm', fn)

  dispose: =>
    @subscriptions.dispose()
    @movementCommandSubscriptions?.dispose()
    @emitter.emit('did-dispose')
    @emitter.dispose()
    @overlayMarker.destroy()
