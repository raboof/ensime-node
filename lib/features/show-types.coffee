TypeHoverElement = require '../views/tooltip-view'
$ = require 'jquery'
{bufferPositionFromMouseEvent, pixelPositionFromMouseEvent, getElementsByClass} = require '../utils'
{formatType} = require '../formatting'
SubAtom = require('sub-atom')

# This one lives as one per file for all instances with an instanceLookup.
class ShowTypes
  constructor: (@editor, @clientLookup) ->
    @disposables = new SubAtom

    @editorView = atom.views.getView(@editor)
    @editorElement = @editorView.rootElement

    @disposables.add @editorElement, 'mousemove', '.scroll-view', (e) =>
      @clearExprTypeTimeout()
      @exprTypeTimeout = setTimeout (=>
        @showExpressionType e
      ), 100

    @disposables.add @editorElement, 'mouseout', '.scroll-view', (e) =>
      @clearExprTypeTimeout()

    @disposables.add @editor.onDidDestroy =>
      @deactivate()

  # get expression type under mouse cursor and show it
  showExpressionType: (e) ->
    return if @marker?

    pixelPt = pixelPositionFromMouseEvent(@editor, e)
    bufferPt = bufferPositionFromMouseEvent(@editor, e)
    
    offset = @editor.getBuffer().characterIndexForPosition(bufferPt)

    @clientLookup()?.getSymbolAtPoint(@editor.getPath(), offset, (msg) =>
      @marker = @editor.markBufferPosition(bufferPt)
      if(@marker)
        @overlayDecoration = @editor.decorateMarker(@marker, {type: 'overlay', item: new TypeHoverElement().initialize(formatType(msg.type)), class: "blabla"})
        console.log(['overlay: ', @overlayDecoration])
    )

  deactivate: ->
    @clearExprTypeTimeout()
    @disposables.dispose()

  # helper function to hide tooltip and stop timeout
  clearExprTypeTimeout: ->
    if @exprTypeTimeout?
      clearTimeout @exprTypeTimeout
      @exprTypeTimeout = null
    @hideExpressionType()

  hideExpressionType: ->
    if(@firstMarker)
      @marker?.destroy()
    @firstMarker = true
    @marker = null
    

module.exports = ShowTypes
