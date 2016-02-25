{formatCompletionsSignature} = require '../ensime-client/formatting'
SubAtom = require 'sub-atom'

module.exports = (clientLookup) ->
  disposables = new SubAtom
  noOfAutocompleteSuggestions = undefined
  
  disposables.add atom.config.observe 'Ensime.noOfAutocompleteSuggestions', (value) ->
    noOfAutocompleteSuggestions = value

  {
    dispose: -> disposables.dispose()
    getCompletions: (textBuffer, bufferPosition, callback) ->
      file = textBuffer.getPath()
      offset = textBuffer.characterIndexForPosition(bufferPosition)
      clientLookup(textBuffer)?.getCompletions(file, textBuffer.getText(), offset, noOfAutocompleteSuggestions, (result) ->
        completions = result.completions
        
        if(completions)
          translate = (c) ->
            typeSig = c.typeSig
            if(c.isCallable)
              formattedSignature = formatCompletionsSignature(typeSig.sections)
              {
                leftLabel: c.typeSig.result
                snippet: "#{c.name}#{formattedSignature}"
              }
            else
              {
                snippet: c.name
              }
              
          autocompletions = (translate c for c in completions)
          callback(autocompletions)
      )
    onDidInsertSuggestion: (thang) ->
      console.log(['inserted suggestion', thang])
  }
