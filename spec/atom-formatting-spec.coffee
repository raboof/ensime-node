root = '..'
{formatTypeAsHtml} = require "#{root}/lib/atom-formatting"

describe 'rich atom specific type hover formatter', ->
  it "should format |@| correctly", ->
    typeStr = """
        {
          "typehint": "ArrowTypeInfo",
          "name": "[B](fb: F[B])scalaz.syntax.ApplicativeBuilder[F,A,B]",
          "resultType": {
            "name": "<refinement>",
            "fullName": "scalaz.syntax.ApplyOps$<refinement>",
            "typehint": "BasicTypeInfo",
            "typeArgs": [],
            "members": [],
            "declAs": {
              "typehint": "Class"
            }
          },
          "paramSections": [
            {
              "params": [
                [
                  "fb",
                  {
                    "name": "F",
                    "fullName": "scalaz.syntax.F",
                    "typehint": "BasicTypeInfo",
                    "typeArgs": [
                      {
                        "name": "B",
                        "fullName": "scalaz.syntax.B",
                        "typehint": "BasicTypeInfo",
                        "typeArgs": [],
                        "members": [],
                        "declAs": {
                          "typehint": "Nil"
                        }
                      }
                    ],
                    "members": [],
                    "declAs": {
                      "typehint": "Nil"
                    }
                  }
                ]
              ],
              "isImplicit": false
            }
          ]
        }
    """
    type = JSON.parse(typeStr)
