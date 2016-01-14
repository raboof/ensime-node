# Super quick one that just adds the first in list
# TODO: make ui for selecting

module.exports = class ImportSuggestions
  constructor: ->
    @refactorings = new (require('./refactorings'))

  getImportSuggestions: (client, buffer, pos, symbol) ->
    file = buffer.getPath()

    req =
      typehint: 'ImportSuggestionsReq'
      file: file
      point: pos
      names: [symbol]
      maxResults: 10

    client.post(req, (res) =>
      @refactorings.getAddImportPatch(client, res.symLists[0][0].name, file, (importResponse) =>
        @refactorings.maybeApplyPatch(client, importResponse, () ->
          client.typecheckBuffer(buffer)
        )
      )
    )
