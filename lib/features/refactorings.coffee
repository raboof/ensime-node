fs = require 'fs'
JsDiff = require 'diff'

module.exports = class Refactorings
  constructor: ->
    @ensimeRefactorId = 1

  getRefactorPatch: (client, refactoring, interactive, callback) ->
    msg =
      typehint: 'RefactorReq'
      procId: @ensimeRefactorId++
      params: refactoring
      interactive: interactive

    client.post(msg, callback)

  getAddImportPatch: (client, qualifiedName, file, callback) ->
    @getRefactorPatch(client,
      typehint: "AddImportRefactorDesc"
      qualifiedName: qualifiedName
      file: file
    , false, callback)

  getOrganizeImportsPatch: (client, file, callback) ->
    @getRefactorPatch(client,
      typehint: "OrganiseImportsRefactorDesc"
      file: file
    , false, callback)


  # Applies unified paths to editors
  # TODO: maybe just parse patch and do it manually within atom to retain cursor position and more easily extend
  # with coolness?
  applyPatch: (client, patchPath, callback = ->) ->
    fs.readFile(patchPath, 'utf8', (err, unifiedDiff) ->
      options =
        loadFile: (index, callback) ->
          # TODO: Should we always read the "before"-file from disk? ensime could have index of unsaved edits right?
          if(index.oldFileName)
            fs.readFile(index.oldFileName, 'utf8', callback)
          else
            callback("no edits")
            
        patched: (index, content) ->
          atom.workspace.open(index.newFileName).then (editor) ->
            editor.setText(content)

        complete: (err) ->
          if not err
            callback()
          else
            console.log(err)

      JsDiff.applyPatches(unifiedDiff, options)

    )

  maybeApplyPatch: (client, result, callback = ->) ->
    if(result.typehint == 'RefactorDiffEffect')
      @applyPatch(client, result.diff, callback)
    else
      console.log(res)


  organizeImports: (client, file, callback = -> ) ->
    @getOrganizeImportsPatch(client, file, (res) =>
      @maybeApplyPatch(client, res, callback)
    )
