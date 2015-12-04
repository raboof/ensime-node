ImplicitInfo = require '../model/implicit-info'
SubAtom = require 'sub-atom'
{log} = require '../utils'
class Implicits
  constructor: (@editor, @clientLookup) ->
    # @gutter = @editor.gutterWithName "ensime-implicits"
    # @gutter ?= @editor.addGutter
    #   name: "ensime-implicits"
    #   priority: 10
    @disposables = new SubAtom

    # @handleSetting(atom.config.get('Ensime.markImplicitsAutomatically'))
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
    @clientLookup()?.typecheckBuffer(b, (typecheckResult) =>
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
      @clientLookup()?.post(msg, (result) =>
        log(result)

        createMarker = (info) =>
          range = [b.positionForCharacterIndex(parseInt(info.start)), b.positionForCharacterIndex(parseInt(info.end))]
          marker = @editor.markBufferRange(range,
              invalidate: 'inside'
              type: 'implicit'
              info: info
          )
          @editor.decorateMarker(marker,
              type: 'highlight'
              class: 'implicit'
          )


          @editor.decorateMarker(marker,
              type: 'line-number'
              class: 'implicit'
          )


          marker
        markers = (createMarker info for info in result.infos)
      )
    )

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
