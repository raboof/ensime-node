import api = require("./typings/server-api");

import _ = require ('lodash');

const functionMatcher = new RegExp("scala\\.Function\\d{1,2}")
const scalaPackageMatcher = new RegExp("scala\\.([\\s\\S]*)")
const refinementMatcher = new RegExp("(.*)\\$<refinement>") // scalaz.syntax.ApplyOps$<refinement>

export const fixQualifiedTypeName = (theType) => {
    const refinementMatch = refinementMatcher.exec(theType.fullName)
    if(refinementMatch)
      return refinementMatch[1]
    else
      return theType.fullName
}
    
export function fixShortTypeName(theType) {
    const refinementMatch = refinementMatcher.exec(theType.fullName)
    if(refinementMatch)
        return _.last(_.split(theType.fullName, "."))
    else
        return theType.name
}
    
    
export function formatTypeNameAsString(theType: api.Type) : string {
    const scalaPackage = scalaPackageMatcher.exec(theType.fullName)
    if(scalaPackage)
        return scalaPackage[1]
    else {
        return theType.name
    }
}


    
// # For hover
// # typeNameFormatter: function from {name, fullName} -> Html/String
export const formatTypeWith = (typeNameFormatter: (x: any) => string) => (theType: any) => {
    function recur(theType) {

        const formatParam = (param) => {
          const type = recur(param[1])
          return `${param[0]}: ${type}`
        }
            
        const formatParamSection = (paramSection) => {
          const p = paramSection.params.map(formatParam)
          return p.join(", ")
        }

        const formatParamSections = (paramSections) => {
          const sections = paramSections.map(formatParamSection)
          return "(" + sections.join(")(") + ")"
        }

        const formatBasicType = (theType) => {
            const name = typeNameFormatter(theType)
              
            const typeArgs = theType.typeArgs
            if(! typeArgs || typeArgs.length == 0)
              return name
            else {
              const formattedTypeArgs = typeArgs.map(recur)
              if(theType.fullName == 'scala.<byname>')
                return "=> " + formattedTypeArgs.join(", ")
              else if(theType.fullName == 'scala.<repeated>')
                return formattedTypeArgs.join(", ") + "*"
              else if(theType.fullName == "scala.Function1") {
                const i = formattedTypeArgs[0]
                const o = formattedTypeArgs[1]
                return i + " => " + o
              } else if(functionMatcher.test(theType.fullName)) {
                const result = _.last(formattedTypeArgs)
                const params = _.initial(formattedTypeArgs)
                return `(${params.join(", ")}) => ${result}`
              } else
                return name + `[${formattedTypeArgs.join(", ")}]`
            }
        }

        if(theType.typehint === "ArrowTypeInfo")
          return formatParamSections(theType.paramSections) + ": " + recur(theType.resultType)
        else if(theType.typehint === "BasicTypeInfo")
          return formatBasicType(theType)
    }
    return recur(theType)
}

export function formatImplicitInfo(info: api.ImplicitParamInfo | api.ImplicitConversionInfo): string {
    if (info.typehint == 'ImplicitParamInfo') {
        const implicitParamInfo = <api.ImplicitParamInfo>info
        return `Implicit parameters added to call of ${implicitParamInfo.fun.localName}: (${_.map(implicitParamInfo.params, (p) => p.localName).join(", ")})`
    } else if (info.typehint == 'ImplicitConversionInfo') {
        const implicitConversionInfo = <api.ImplicitConversionInfo>info
        return `Implicit conversion: ${implicitConversionInfo.fun.localName}`
    }
}


export const formatType = formatTypeWith(formatTypeNameAsString);
