# Helper for looking up ScalaDoc.

class Documentation

  constructor: (@editor) ->
    @textBuffer = @editor.getBuffer()

  # If there's selected text, what's the to/from point?
  selectedPoint: () ->
    range = @editor.getSelectedBufferRange()
    {
      from: @textBuffer.characterIndexForPosition(range.start)
      to: @textBuffer.characterIndexForPosition(range.end)
    }

  # If there's no selected text, just send the offset.
  # ENSIME appears to figure out what we want just from this!
  cursorPoint: () ->
    bufferPosition = @editor.getCursorBufferPosition()
    offset = @textBuffer.characterIndexForPosition(bufferPosition)
    {
      from: offset
      to: offset
    }

  getPoint: () ->
    hasSelectedText = @editor.getSelectedText() != ""
    if hasSelectedText then this.selectedPoint() else this.cursorPoint()

  @formUrl: (host, port, path) ->
    alreadyUrl = (path.indexOf("//") != -1)
    if alreadyUrl then path else "http://#{host}:#{port}/#{path}"

  @openDoc = (url) =>
    split = atom.config.get('Ensime.documentationSplit')
    switch split
      when 'external-browser' then shell.openExternal(url)
      else atom.workspace.open(url, {split: split})

module.exports = Documentation
