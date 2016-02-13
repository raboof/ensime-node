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




formatParam = (param) ->
  result = formatType(param[1])
  "#{param[0]}: #{result}"

formatParamSection = (paramSection) ->
  p = (formatParam(param) for param in paramSection.params)
  p.join(", ")

formatParamSections = (paramSections) ->
  sections = (formatParamSection(paramSection) for paramSection in paramSections)
  "(" + sections.join(")(") + ")"


functionMatcher = /scala\.Function\d{1,2}/
scalaPackageMatcher = /scala\.([\s\S]*)/

# For hover
formatType = (theType) ->
  if(theType.typehint == "ArrowTypeInfo")
    formatParamSections(theType.paramSections) + ": " + formatType(theType.resultType)
  else if(theType.typehint == "BasicTypeInfo")
    typeArgs = theType.typeArgs

    scalaPackage = scalaPackageMatcher.exec(theType.fullName)
    name =
      if(scalaPackage)
        scalaPackage[1]
      else
        if theType.declAs.typehint in ['Class', 'Trait', 'Object', 'Interface'] then theType.fullName else theType.name

    if not typeArgs || typeArgs.length == 0
      name
    else
      formattedTypeArgs = (formatType(typeArg) for typeArg in typeArgs)
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




formatImplicitInfo = (info) ->
  if info.typehint == 'ImplicitParamInfo'
    "Implicit parameters added to call of #{info.fun.localName}: (#{_.map(info.params, (p) -> p.localName).join(", ")})"
  else if info.typehint == 'ImplicitConversionInfo'
    "Implicit conversion: #{info.fun.localName}"

module.exports = {
  formatCompletionsSignature,
  formatType,
  formatImplicitInfo
}
