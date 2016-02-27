getSymbolDesignations = (client, editor) ->
  b = editor.getBuffer()
  range = b.getRange()
  startO = b.characterIndexForPosition(range.start)
  endO = b.characterIndexForPosition(range.end)

  msg = {
    "typehint":"SymbolDesignationsReq"
    "requestedTypes": symbolTypehints
    "file": b.getPath()
    "start": startO
    "end": endO
  }


  new Promise (resolve, reject) ->
    client.post(msg, (result) ->
      syms = result.syms

      markers = (sym) ->
        startPos = b.positionForCharacterIndex(parseInt(sym[1]))
        endPos = b.positionForCharacterIndex(parseInt(sym[2]))
        marker = editor.markBufferRange([startPos, endPos],
                invalidate: 'inside',
                class: "scala #{sym[0]}"
                )
        decoration = editor.decorateMarker(marker,
          type: 'highlight',
          class: sym[0]
        )
        marker

      makeCodeLink = (marker) ->
        range: marker.getBufferRange()

      makers = (markers sym for sym in syms)
      codeLinks = (makeCodeLink marker for maker in makers)

      resolve(codeLinks)
    )

symbols = [
  "ObjectSymbol"
  ,"ClassSymbol"
  ,"TraitSymbol"
  ,"PackageSymbol"
  ,"ConstructorSymbol"
  ,"ImportedNameSymbol"
  ,"TypeParamSymbol"
  ,"ParamSymbol"
  ,"VarFieldSymbol"
  ,"ValFieldSymbol"
  ,"OperatorFieldSymbol"
  ,"VarSymbol"
  ,"ValSymbol"
  ,"FunctionCallSymbol"]

symbolTypehints = _.map(symbols, (symbol) -> {"typehint": "#{symbol}"})
