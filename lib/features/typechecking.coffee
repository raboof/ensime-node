{MessagePanelView, LineMessageView} = require 'atom-message-panel'
_ = require 'lodash'
{isScalaSource} = require '../utils'
log = require('loglevel').getLogger('ensime.typechecking')



module.exports = (indieLinter) ->
  lints = []
  timeout = undefined

  # API
  noteToLint = (note) ->
    type: switch note.severity.typehint
      when "NoteError" then "Error"
      when "NoteWarn" then "Warning"
      else ""
    text: note.msg
    # TODO: This is only true if error doesn't span two lines. Since we don't have buffer here it might be
    # good enough? Or not?
    range: [[note.line - 1, note.col - 1], [note.line - 1, note.col - 1 + (note.end - note.beg)]]
    filePath: note.file
        
  addLints = (notes) ->
    for note in notes
      if(not note.file.includes('dep-src'))
        lints.push(noteToLint(note))
    
  {
    addScalaNotes: (msg) ->
      notes = msg.notes
      addLints(notes)
      log.trace(['lints: ', lints])
      
      doit = ->
        # https://github.com/atom-community/linter/issues/1075
        indieLinter.setMessages(JSON.parse(JSON.stringify(lints)))
        
      if timeout
        clearTimeout(timeout)
      timeout = setTimeout(doit, 100)
      
    clearScalaNotes: ->
      lints = []
      indieLinter.deleteMessages()
        
    destroy: ->
      indieLinter.dispose()
  }
