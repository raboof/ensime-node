module.exports = class Refactorings
  constructor: ->
    @ensimeRefactorId = 1

  prepareRefactoring: (client, refactoring, interactive, callback) ->
    msg =
      typehint: 'PrepareRefactorReq'
      tpe: '' #ignored
      procId: @ensimeRefactorId++
      params: refactoring
      interactive: interactive

    client.post(msg, callback)

  prepareAddImport: (client, qualifiedName, file, callback) ->
    @prepareRefactoring({
      typehint: "AddImportRefactorDesc"
      qualifiedName: qualifiedName
      file: file
    }, false, callback)

  prepareOrganizeImports: (client, file, callback) ->
    @prepareRefactoring({
      typehint: "OrganiseImportsRefactorDesc"
      file: file
    }, false, callback)

  organizeImports: (client, file, callback = -> ) ->
    @prepareOrganizeImports(client, file, (res) =>
      if(res.status == 'success')
        updatedRanges = (@performTextEdit change for change in res.changes)
      )


  # typehint: TextEdit
  performTextEdit: (change, callback = -> ) ->
    atom.workspace.open(change.file).then (editor) ->
      b = editor.getBuffer()
      from = b.positionForCharacterIndex(parseInt(change.from))
      to = b.positionForCharacterIndex(parseInt(change.to))
      newRange = editor.setTextInBufferRange([from, to], change.text)
