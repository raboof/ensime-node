ImplicitInfo = require '../model/implicit-info'
SubAtom = require 'sub-atom'
{log} = require '../utils'
class Implicits
  constructor: (@editor, @instanceLookup) ->
    @disposables = new SubAtom

    @disposables.add atom.config.observe 'Ensime.markImplicitsAutomatically', (setting) => @handleSetting(setting)


  handleSetting: (markImplicitsAutomatically) ->
    if(markImplicitsAutomatically)
      @showImplicits()
      @saveListener = @editor.onDidSave(() => @showImplicits())
      @disposables.add @saveListener
    else
      @saveListener?.dispose()
      @disposables.remove @saveListener


  showImplicits: ->
    log("showImplicits this: " + this)
    b = @editor.getBuffer()
    
    instance = @instanceLookup()
        
    continuation = =>
      range = b.getRange()
      startO = b.characterIndexForPosition(range.start)
      endO = b.characterIndexForPosition(range.end)

      msg =
        "typehint":"ImplicitInfoReq"
        "file": b.getPath()
        "range":
          "from": startO
          "to": endO

      @clearMarkers()
      instance.client.post(msg, (result) =>
        log(result)

        createMarker = (info) =>
          range = [b.positionForCharacterIndex(parseInt(info.start)), b.positionForCharacterIndex(parseInt(info.end))]
          spot = [range[0], range[0]]

          markerRange = @editor.markBufferRange(range,
              type: 'implicit'
              info: info
          )
          markerSpot = @editor.markBufferRange(spot,
              type: 'implicit'
              info: info
          )
          @editor.decorateMarker(markerRange,
              type: 'highlight'
              class: 'implicit'
          )
          @editor.decorateMarker(markerSpot,
              type: 'line-number'
              class: 'implicit'
          )

        markers = (createMarker info for info in result.infos)
      )
    
    # If source path is under sourceRoots and modified, typecheck it first
    if(instance)
      if(instance.isSourceOf(@editor.getPath()) and @editor.isModified())
        instance.client.typecheckBuffer(b, (typecheckResult) -> continuation())
      else
        continuation()
        
  showImplicitsAtCursor: ->
    pos = @editor.getCursorBufferPosition()
    log("pos: " + pos)
    markers = @findMarkers({type: 'implicit', containsPoint: pos})
    infos = markers.map (marker) -> marker.properties.info
    implicitInfo = new ImplicitInfo(infos, @editor, pos)


  clearMarkers: ->
    marker.destroy() for marker in @findMarkers()
    @overlayMarker?.destroy()

  findMarkers: (attributes = {type: 'implicit'}) ->
    @editor.getBuffer().findMarkers(attributes)

  deactivate: ->
    @disposables.dispose()
    @clearMarkers()


# _.extend(attributes, class: 'bookmark')

module.exports = Implicits
