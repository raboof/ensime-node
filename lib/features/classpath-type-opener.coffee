# NOT USED
# Idea is to register an own uri type for classpath's when we start using source jars.
# Currently it was easier with normal TextEditor.

module.exports = (client) -> (uri) ->
  if(uri.startsWith("ensime://classpath/"))
    return new TextEditor(uri)
  
