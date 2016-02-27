fs = require 'fs'
JsDiff = require 'diff'
log = require('loglevel').getLogger('ensime.refactorings')

# Refactorings should be cleaned of Atom stuff and put in client module. Add callback for what to do with patches
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


  # Applies unified paths to editors using files. Not used anymore.
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
            log.trace(err)
      JsDiff.applyPatches(unifiedDiff, options)

    )
    
    
  # Very atom specific. move out
  applyPatchInEditors: (client, patchPath, callback = ->) ->
    fs.readFile(patchPath, 'utf8', (err, unifiedDiff) ->
      patches = JsDiff.parsePatch(unifiedDiff)
      for patch in patches
        log.trace(patch)
        if(patch.oldFileName == patch.newFileName)
          atom.workspace.open(patch.newFileName).then (editor) ->
            b = editor.getBuffer()
            for hunk in patch.hunks
              range = [[hunk.oldStart - 1, 0], [hunk.oldStart + hunk.oldLines - 2, 0]]
              log.trace ['range', range]
              newLines = _.filter(hunk.lines, (l) -> not l.startsWith('-'))
              newLines = _.map(newLines, (l) -> if(l.length == 1) then l else l.substring(1, l.length))
              toInsert = _.join(newLines, '\n')
              b.setTextInRange(range, toInsert)
        else
          atom.notifications.addError("Sorry, no file renames yet")
    )
        
  maybeApplyPatch: (client, result, callback = ->) ->
    if(result.typehint == 'RefactorDiffEffect')
      @applyPatchInEditors(client, result.diff, callback)
    else
      log.trace(res)


  organizeImports: (client, file, callback = -> ) ->
    @getOrganizeImportsPatch(client, file, (res) =>
      @maybeApplyPatch(client, res, callback)
    )
    
    
  doImport: (client, name, file, buffer, callback = ->) ->
    @getAddImportPatch(client, name, file, (importResponse) =>
      @maybeApplyPatch(client, importResponse, () ->
        client.typecheckBuffer(buffer.getPath(), buffer.getText(), callback)
      )
    )
  
