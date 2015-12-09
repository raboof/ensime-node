SubAtom = require 'sub-atom'
{log} = require '../utils'
class InlineDecorators
  constructor: (@editor, @client, @type, @hintMatch, @configName) ->
    @disposables = new SubAtom

    @buffer = @editor.getBuffer()

    @decorators = new WeakMap

    @markers = []

    @show = atom.config.get(@configName)

    @disposables.add atom.config.observe @configName, (setting) => @handleSetting(setting)

  handleSetting: (markInline) ->
    @show = markInline
    @updateDecorations()

  addScalaNotes: (msg) ->
    for note in msg.notes
      if( note.severity.typehint == @hintMatch && @editor.getPath() == note.file)
        range = [@buffer.positionForCharacterIndex(parseInt(note.beg)), @buffer.positionForCharacterIndex(parseInt(note.end))]
        markerRange = @editor.markBufferRange(range,
          type: @type+"-range"
        )
        markerSpot = @editor.markBufferPosition([note.line - 1, note.col - 1],
          type: @type+"-spot"
        )
        marker = { spot: markerSpot, range: markerRange }
        @markers.push( marker )
        if(@show)
          @decorateSpot(marker)
          @decorateRange(marker)


  decorateSpot: (marker) ->
    @decorators.set(marker.spot, @editor.decorateMarker(marker.spot,
      type: 'line-number'
      class: @type
    ))

  decorateRange: (marker) ->
    @decorators.set(marker.range, @editor.decorateMarker(marker.range,
      type: 'highlight'
      class: @type
    ))

  updateDecorations: ->
    for marker in @markers
      if @show
        if not @decorators.has(marker.spot) then @decorateSpot(marker)
        if not @decorators.has(marker.range) then @decorateRange(marker)
      else
        @decorators.get(marker.spot)?.destroy()
        @decorators.delete(marker.spot)
        @decorators.get(marker.range)?.destroy()
        @decorators.delete(marker.range)


  clearScalaNotes: ->
    for marker in @markers
      marker.spot.destroy()
      marker.range.destroy()
    @markers = []

  deactivate: ->
    @disposables.dispose()
    @clearScalaNotes()

class InlineErrors extends InlineDecorators
  constructor: (@editor, @client) ->
    super(@editor, @client, 'error', 'NoteError', 'Ensime.markErrorsInline')

class InlineWarnings extends InlineDecorators
  constructor: (@editor, @client) ->
    super(@editor, @client, 'warn', 'NoteWarn', 'Ensime.markWarningsInline')

module.exports = { InlineErrors, InlineWarnings }
