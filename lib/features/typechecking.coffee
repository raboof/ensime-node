{MessagePanelView, LineMessageView} = require 'atom-message-panel'
_ = require 'lodash'
{log, isScalaSource} = require '../utils'

class ErrorSummary
  constructor: (@errors, @warnings) ->

  @zero: new ErrorSummary 0, 0

  add: (note) ->
    switch note.severity.typehint
      when "NoteError" then new ErrorSummary @errors + 1, @warnings
      when "NoteWarn" then new ErrorSummary @errors, @warnings + 1
      else new ErrorSummary @errors, @warnings

  addNotes: (notes) ->
    _.reduce notes,
      (sum, note) -> sum.add note,
      this

  text: () ->
    switch (@errors + @warnings)
      when 0 then ''
      else 'Errors: ' + @errors + ' Warnings: ' + @warnings


module.exports =
class TypeChecking

  constructor: ->
    @messages = new MessagePanelView
      title: 'Ensime'
    @messages.attach()
    @summary = ErrorSummary.zero

  addScalaNotes: (msg) ->
    notes = msg.notes

    # Nah? We might already have stuff
    @notesByFile = _.groupBy(notes, (note) -> note.file)

    addNoteToMessageView = (note) =>
      @messages.add new LineMessageView
        file: note.file
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
        @summary = @summary.addNotes(notes)

    @messages.setSummary { summary: @summary.text() }

  hide: ->
    @messages?.hide()

  show: ->
    @messages.show()

  clearScalaNotes: ->
    @messages.clear()
    @messages.setSummary { summary: '' }
    @summary = ErrorSummary.zero

  # cleanup
  destroy: ->
    @messages?.clear()
    @messages?.close()
    @messages = null
