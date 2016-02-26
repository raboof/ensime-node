# Super quick one that just adds the first in list
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
      # TODO: Add ui for selection
      name = res.symLists[0][0].name
      
      @refactorings.doImport(client, name, file, buffer)
    )
