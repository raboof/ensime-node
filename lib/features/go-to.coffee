goToTypeAtPoint = (client, textBuffer, bufferPosition) ->
  offset = textBuffer.characterIndexForPosition(bufferPosition)

  client.getSymbolAtPoint(textBuffer.getPath(), offset, (msg) ->
    pos = msg.declPos
    # Sometimes no pos
    if(pos)
      goToPosition(pos)
    else
      atom.notifications.addError("No declPos in response from Ensime server, cannot go anywhere :(")
  )

goToPosition = (pos) ->
  if(pos.typehint == "LineSourcePosition")
    atom.workspace.open(pos.file).then (editor) ->
      editor.setCursorBufferPosition([parseInt(pos.line), 0])
  else
    atom.workspace.open(pos.file).then (editor) ->
      targetEditorPos = editor.getBuffer().positionForCharacterIndex(parseInt(pos.offset))
      editor.setCursorBufferPosition(targetEditorPos)


module.exports = {
  goToTypeAtPoint
  goToPosition
}
