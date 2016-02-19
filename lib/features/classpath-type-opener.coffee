module.exports = (client) -> (uri) ->
  console.log('ensime uri resolver started')
  if(uri.startsWith("ensime://classpath/"))
    console.log("ensime type opener match")
    return new TextEditor(uri)
  
