{MessagePanelView, LineMessageView} = require 'atom-message-panel'
_ = require 'lodash'
{log, isScalaSource} = require '../utils'



module.exports = (indieLinter) ->
  lints = []

  # API
  noteToLint = (note) ->
    filePath: note.file
    # TODO: This is only true if error doesn't span two lines. Since we don't have buffer here it might be
    # good enough? Or not?
    range: [[note.line - 1, note.col - 1], [note.line - 1, note.col - 1 + (note.end - note.beg)]]
    text: note.msg
    type: switch note.severity.typehint
      when "NoteError" then "Error"
      when "NoteWarn" then "Warning"
      else ""
        
  addLints = (notes) ->
    for note in notes
      if(not note.file.includes('dep-src'))
        lints.push(noteToLint(note))
    
  {
    addScalaNotes: (msg) ->
      notes = msg.notes
      addLints(notes)
      console.log(['lints: ', lints])
      indieLinter.setMessages(lints)
      
    clearScalaNotes: ->
      lints = []
      indieLinter.deleteMessages()
        
    destroy: ->
      indieLinter.dispose()
  }
