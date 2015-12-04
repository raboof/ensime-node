{formatCompletionsSignature} = require '../formatting'
SubAtom = require 'sub-atom'

module.exports =
class AutocompletePlusProvider

  constructor: (@clientLookup) ->
    @disposables = new SubAtom
    @disposables.add atom.config.observe 'Ensime.noOfAutocompleteSuggestions', (value) =>
      @noOfAutocompleteSuggestions = value

  dispose: ->
    @disposables.dispose()

  getCompletions: (textBuffer, bufferPosition, callback) =>
    file = textBuffer.getPath()
    offset = textBuffer.characterIndexForPosition(bufferPosition)

    msg =
      typehint: "CompletionsReq"
      fileInfo:
        file: file
        contents: textBuffer.getText()
      point: offset
      maxResults: @noOfAutocompleteSuggestions
      caseSens: false
      reload: true

    @clientLookup(textBuffer)?.post(msg, (result) ->
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
        ### Autocomplete + :
        suggestion =
          text: 'someText' # OR
          snippet: 'someText(${1:myArg})'
          replacementPrefix: 'so' # (optional)
          type: 'function' # (optional)
          leftLabel: '' # (optional)
          leftLabelHTML: '' # (optional)
          rightLabel: '' # (optional)
          rightLabelHTML: '' # (optional)
          iconHTML: '' # (optional)
        ###
        callback(autocompletions)
    )
