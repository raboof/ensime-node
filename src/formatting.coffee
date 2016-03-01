_ = require 'lodash'

# This is the one returned from completions
formatCompletionsSignature = (paramLists) ->
  formatParamLists = (paramLists) ->
    i = 0
    formatParamList = (paramList) ->
      formatParam = (param) ->
        i = i+1
        "${#{i}:#{param[0]}: #{param[1]}}"
      p = (formatParam(param) for param in paramList)
      "(" + p.join(", ") + ")"

    formattedParamLists = (formatParamList paramList for paramList in paramLists)
    formattedParamLists.join("")
  if(paramLists)
    formatParamLists(paramLists)
  else
    ""


functionMatcher = /scala\.Function\d{1,2}/
scalaPackageMatcher = /scala\.([\s\S]*)/

refinementMatcher = /(.*)\$<refinement>/ # scalaz.syntax.ApplyOps$<refinement>

fixQualifiedTypeName = (theType) ->
  refinementMatch = refinementMatcher.exec(theType.fullName)
  if(refinementMatch)
    refinementMatch[1]
  else
    theType.fullName
    
fixShortTypeName = (theType) ->
  refinementMatch = refinementMatcher.exec(theType.fullName)
  if(refinementMatch)
    _.last(_.split(theType.fullName, "."))
  else
    theType.name
    
    
formatTypeNameAsString = (theType) ->
  scalaPackage = scalaPackageMatcher.exec(theType.fullName)
  if(scalaPackage)
    scalaPackage[1]
  else
    if theType.declAs.typehint in ['Class', 'Trait', 'Object', 'Interface'] then theType.fullName else theType.name


    
# For hover
# typeNameFormatter: function from {name, fullName} -> Html/String
formatType = (typeNameFormatter) -> (theType) ->
  recur = (theType) ->
    formatParam = (param) ->
      type = recur(param[1])
      "#{param[0]}: #{type}"
        
    formatParamSection = (paramSection) ->
      p = (formatParam(param) for param in paramSection.params)
      p.join(", ")

    formatParamSections = (paramSections) ->
      sections = (formatParamSection(paramSection) for paramSection in paramSections)
      "(" + sections.join(")(") + ")"

      
    formatBasicType = (theType) ->
      name = typeNameFormatter(theType)
        
      typeArgs = theType.typeArgs
      if not typeArgs || typeArgs.length == 0
        name
      else
        formattedTypeArgs = (recur(typeArg) for typeArg in typeArgs)
        if theType.fullName == 'scala.<byname>'
          "=> " + formattedTypeArgs.join(", ")
        else if theType.fullName == 'scala.<repeated>'
          formattedTypeArgs.join(", ") + "*"
        else if theType.fullName == "scala.Function1"
          [i, o] = formattedTypeArgs
          i + " => " + o
        else if functionMatcher.test(theType.fullName)
          [params..., result] = formattedTypeArgs
          "(#{params.join(", ")}) => #{result}"
        else
          name + "[#{formattedTypeArgs.join(", ")}]"

    if(theType.typehint == "ArrowTypeInfo")
      formatParamSections(theType.paramSections) + ": " + recur(theType.resultType)
    else if(theType.typehint == "BasicTypeInfo")
      formatBasicType(theType)
  
  recur(theType)
  


formatImplicitInfo = (info) ->
  if info.typehint == 'ImplicitParamInfo'
    "Implicit parameters added to call of #{info.fun.localName}: (#{_.map(info.params, (p) -> p.localName).join(", ")})"
  else if info.typehint == 'ImplicitConversionInfo'
    "Implicit conversion: #{info.fun.localName}"

module.exports = {
  formatCompletionsSignature,
  formatType: formatType(formatTypeNameAsString),
  formatTypeWith: formatType,
  formatImplicitInfo,
  fixQualifiedTypeName,
  fixShortTypeName
}
