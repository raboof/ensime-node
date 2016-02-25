module.exports = (client) -> (uri) ->
  if(uri.startsWith("ensime://classpath/"))
    return new TextEditor(uri)
  
