{MessagePanelView, LineMessageView} = require 'atom-message-panel'
_ = require 'lodash'
{log, isScalaSource} = require '../utils'

module.exports =
class TypeChecking

  constructor: ->
    @messages = new MessagePanelView
      title: 'Ensime'
    @messages.attach()


  addScalaNotes: (msg) ->
    notes = msg.notes

    # Nah? We might already have stuff
    @notesByFile = _.groupBy(notes, (note) -> note.file)

    addNoteToMessageView = (note) =>
      file = atom.project.relativizePath(note.file)[1]
      @messages.add new LineMessageView
        file: file
        line: note.line
        character: note.col
        message: note.msg
        className: switch note.severity.typehint
          when "NoteError" then "highlight-error"
          when "NoteWarn" then "highlight-warning"
          else ""

    for file, notes of @notesByFile
      if(not file.includes('dep-src')) # TODO: put under flag
        addNoteToMessageView note for note in notes


  clearScalaNotes: ->
    @messages.clear()

  # cleanup
  destroy: ->
    @messages.clear()
    @messages?.close()
    @messages = null
