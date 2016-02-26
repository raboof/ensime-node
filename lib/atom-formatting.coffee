# Atom specific formatting
{formatType, formatTypeWith, fixQualifiedTypeName, fixShortTypeName} = require './ensime-client/formatting.coffee'

formatTypeNameAsHtmlWithLink = (theType) ->
  qualifiedName = encodeURIComponent(fixQualifiedTypeName(theType))
  shortName = fixShortTypeName(theType)
  """<a data-qualified-name="#{qualifiedName}" title="#{qualifiedName}">#{shortName}</a>"""


module.exports =
  formatTypeAsString: formatType
  formatTypeAsHtml: formatTypeWith formatTypeNameAsHtmlWithLink
