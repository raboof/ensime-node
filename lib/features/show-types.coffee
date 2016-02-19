TypeHoverElement = require '../views/type-hover-element'
{bufferPositionFromMouseEvent, pixelPositionFromMouseEvent, getElementsByClass} = require '../utils'
{formatTypeAsString, formatTypeAsHtml} = require '../atom-formatting'
SubAtom = require('sub-atom')
DOMListener = require 'dom-listener'

# This one lives as one per file for all instances with an instanceLookup.
class ShowTypes
  constructor: (@editor, @clientLookup) ->
    @disposables = new SubAtom
    @locked = false

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
      
    @disposables.add atom.config.observe 'Ensime.richTypeTooltip', (@richTypeTooltip) =>

  # get expression type under mouse cursor and show it
  showExpressionType: (e) ->
    return if @marker? or @locked

    pixelPt = pixelPositionFromMouseEvent(@editor, e)
    bufferPt = bufferPositionFromMouseEvent(@editor, e)
    
    offset = @editor.getBuffer().characterIndexForPosition(bufferPt)

    client = @clientLookup()
    client?.getSymbolAtPoint(@editor.getPath(), offset, (msg) =>
      @marker?.destroy()
      
      return if(msg.type.fullName == "<none>")
    
      @marker = @editor.markBufferPosition(bufferPt)
      if(@marker)
        typeFormatter =
          if @richTypeTooltip then formatTypeAsHtml else formatTypeAsString
        
        element = new TypeHoverElement().initialize(typeFormatter(msg.type))
        
        @domListener?.destroy()
        @domListener = new DOMListener(element)
        @domListener.add "a", 'click', (event) =>
          a = event.target
          qualifiedName = decodeURIComponent(a.dataset.qualifiedName)
          client.symbolByName(qualifiedName, (response) =>
            if(response.declPos)
              client.goToPosition(response.declPos)
              @unstickAndHide()
          )
          
        @overlayDecoration = @editor.decorateMarker(@marker, {
          type: 'overlay'
          item: element
          class: "ensime"
        })
        
        @stickCommand?.dispose()
        @stickCommand = atom.commands.add 'atom-workspace', "ensime:lock-type-hover", =>
          @locked = true
          @stickCommand.dispose()
          @unstickCommand?.dispose()
          @unstickCommand = atom.commands.add 'atom-workspace', "core:cancel", =>
            @unstickAndHide()
    )
      
  unstickAndHide: ->
    @unstickCommand.dispose()
    @locked = false
    @hideExpressionType()

  deactivate: ->
    @clearExprTypeTimeout()
    @disposables.dispose()
    @stickCommand?.dispose()
    @unstickCommand?.dispose()
    @domListener?.destroy()

  # helper function to hide tooltip and stop timeout
  clearExprTypeTimeout: ->
    if @exprTypeTimeout?
      clearTimeout @exprTypeTimeout
      @exprTypeTimeout = null
    @hideExpressionType()

  hideExpressionType: ->
    return if @locked or not @marker
    @marker?.destroy()
    @marker = null
    @openerDisposable?.dispose()

module.exports = ShowTypes
