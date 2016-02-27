SubAtom = require 'sub-atom'

class AutoTypecheck
  constructor: (@editor, @clientLookup) ->
    @disposables = new SubAtom

    buffer = @editor.getBuffer()
    @disposables.add buffer.onDidSave () =>
      # typecheck file on save
      if atom.config.get('Ensime.typecheckWhen') in ['save', 'typing']
        @clientLookup()?.typecheckFile(@editor.getPath())

     # Typecheck buffer while typing
    @disposables.add atom.config.observe 'Ensime.typecheckWhen', (value) =>
      if(value == 'typing')
        @typecheckWhileTypingDisposable = @editor.onDidStopChanging () =>
          b = @editor.getBuffer()
          @clientLookup()?.typecheckBuffer(b.getPath(), b.getText())
        @disposables.add @typecheckWhileTypingDisposable
      else
        @disposables.remove @typecheckWhileTypingDisposable
        @typecheckWhileTypingDisposable?.dispose()

  deactivate: ->
    @disposables.dispose()

module.exports = AutoTypecheck
