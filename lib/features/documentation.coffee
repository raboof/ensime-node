# Helper for looking up ScalaDoc.
#
# The aim here is to figure out what range to send to ENSIME.
# If there's selected text, we send the range for that.
# Otherwise, we try to figure out what symbol is under the cursor, and send that range.

class Documentation

  constructor: (@editor) ->
    @textBuffer = @editor.getBuffer()

  # See documentation-spec
  @guessRange: (lineText, cursorColumn) ->

    breaks = " .()[],"
    isBreak = (p) -> breaks.indexOf(lineText[p]) != -1
    len = lineText.length

    scanBack = (p) ->
      #console.log("Back",p,lineText[p],isBreak(p))
      switch
        when p == 0 then 0
        when isBreak(p) then p+1
        else scanBack(p-1)

    scanForward = (p) ->
      #console.log("Forward",p,lineText[p],isBreak(p))
      switch
        when p == len then len
        when isBreak(p) then p
        else scanForward(p+1)

    if isBreak(cursorColumn) # We assume we are at the end of a symbol
      [scanBack(cursorColumn-1), cursorColumn]
    else
      [scanBack(cursorColumn), scanForward(cursorColumn)]

  # If there's selected text, what's the to/from point?
  selectedPoint: () ->
    range = @editor.getSelectedBufferRange()
    {
      from: @textBuffer.characterIndexForPosition(range.start)
      to: @textBuffer.characterIndexForPosition(range.end)
    }

  # If there's no selected text, what's the to/from for the symbol under the cursor?
  cursorPoint: () ->
    bufferPosition = @editor.getCursorBufferPosition()
    line = @textBuffer.lineForRow(bufferPosition.row)
    [from, to] = Documentation.guessRange(line,bufferPosition.column)

    # offset is global position correspondong to bufferPosition.column
    offset = @textBuffer.characterIndexForPosition(bufferPosition)
    startOfLineOffset = offset - bufferPosition.column
    # {
    #   from: offset
    #   to: offset+1
    # }
    {
      from: startOfLineOffset + from
      to: startOfLineOffset + to
    }

  getPoint: () ->
    hasSelectedText = @editor.getSelectedText() != ""
    if hasSelectedText then this.selectedPoint() else this.cursorPoint()

  @formUrl: (host, port, path) ->
    alreadyUrl = (path.indexOf("//") != -1)
    if alreadyUrl then path else "http://#{host}:#{port}/#{path}"

module.exports = Documentation
