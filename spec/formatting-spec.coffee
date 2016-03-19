lib = '../lib'
{formatType, formatImplicitInfo, formatTypeNameAsString} = require "#{lib}/formatting"
{readFromString, fromLisp} = require "#{lib}/lisp/lisp"


describe 'formatTypeNameAsString', ->
  it 'should use name', ->
    type =
      "name": "A",
      "fullName": "wrong.A"
      "typehint": "BasicTypeInfo",
      "declAs": {
        "typehint": "Nil"
      }
    expect(formatTypeNameAsString(type)).toBe("A")
    
  it 'should not match scalaz as scala', ->
    type =
      "name": "A",
      "fullName": "scalaz.A"
      "typehint": "BasicTypeInfo",
      "declAs": {
        "typehint": "Nil"
      }
    expect(formatTypeNameAsString(type)).toBe("A")
    
  it 'should match and remove scala.', ->
    type =
      "name": "Integer",
      "fullName": "scala.Integer"
      "typehint": "BasicTypeInfo",
      "declAs": {
        "typehint": "Nil"
      }
    expect(formatTypeNameAsString(type)).toBe("Integer")
    
describe 'formatType', ->
  it "should use simple name for type param", ->
    typeStr = """
          {
            "name": "A",
            "fullName": "scalaz.std.A",
            "typehint": "BasicTypeInfo",
            "typeId": 37,
            "typeArgs": [],
            "members": [],
            "declAs": {
              "typehint": "Nil"
            }
          }
      """

    type = JSON.parse(typeStr)
    expect(formatType(type)).toBe("A")

  it "should format by-name with arrow", ->
    type =
      "name": "<byname>",
      "fullName": "scala.<byname>",
      "typehint": "BasicTypeInfo",
      "typeId": 2861,
      "typeArgs": [
        {
          "name": "T",
          "fullName": "net.liftweb.util.T",
          "typehint": "BasicTypeInfo",
          "typeId": 2862,
          "typeArgs": [],
          "members": [],
          "declAs": {
            "typehint": "Nil"
          }
        }
      ],
      "members": [],
      "declAs": {
        "typehint": "Class"
      }
    expect(formatType(type)).toBe("=> T")

  it "should format <repeated>[X] as X*", ->
    type =
      "name": "<repeated>",
      "fullName": "scala.<repeated>",
      "typehint": "BasicTypeInfo",
      "typeArgs": [
        {
          "name": "ColumnOption",
          "fullName": "slick.ast.ColumnOption",
          "typehint": "BasicTypeInfo",
          "typeArgs": [
            {
              "name": "C",
              "fullName": "slick.profile.C",
              "typehint": "BasicTypeInfo",
              "typeArgs": [
                
              ],
              "members": [
                
              ],
              "declAs": {
                "typehint": "Nil"
              }
            }
          ],
          "members": [
            
          ],
          "declAs": {
            "typehint": "Class"
          }
        }
      ],
      "members": [
        
      ],
      "declAs": {
        "typehint": "Class"
      }
    expect(formatType(type)).toBe("ColumnOption[C]*")
              
              
  it "should format implicit params", ->
    input = {
      "params": [
        {
          "name": "y",
          "localName": "y",
          "declPos": {
            "typehint": "OffsetSourcePosition",
            "file": "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala",
            "offset": 547
          },
          "type": {
            "name": "Int",
            "fullName": "scala.Int",
            "pos": {
              "typehint": "OffsetSourcePosition",
              "file": "/Users/viktor/dev/projects/ensime-test-project/.ensime_cache/dep-src/source-jars/scala/Int.scala",
              "offset": 1093
            },
            "typehint": "BasicTypeInfo",
            "typeId": 14,
            "typeArgs": [],
            "members": [],
            "declAs": {
              "typehint": "Class"
            }
          },
          "isCallable": false,
          "ownerTypeId": 16
        },
        {
          "name": "y",
          "localName": "y",
          "declPos": {
            "typehint": "OffsetSourcePosition",
            "file": "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala",
            "offset": 547
          },
          "type": {
            "name": "Int",
            "fullName": "scala.Int",
            "pos": {
              "typehint": "OffsetSourcePosition",
              "file": "/Users/viktor/dev/projects/ensime-test-project/.ensime_cache/dep-src/source-jars/scala/Int.scala",
              "offset": 1093
            },
            "typehint": "BasicTypeInfo",
            "typeId": 14,
            "typeArgs": [],
            "members": [],
            "declAs": {
              "typehint": "Class"
            }
          },
          "isCallable": false,
          "ownerTypeId": 16
        }
      ],
      "typehint": "ImplicitParamInfo",
      "fun": {
        "name": "curried",
        "localName": "curried",
        "declPos": {
          "typehint": "OffsetSourcePosition",
          "file": "/Users/viktor/dev/projects/ensime-test-project/src/main/scala/Foo.scala",
          "offset": 421
        },
        "type": {
          "resultType": {
            "name": "Int",
            "fullName": "scala.Int",
            "typehint": "BasicTypeInfo",
            "typeId": 14,
            "typeArgs": [],
            "members": [],
            "declAs": {
              "typehint": "Class"
            }
          },
          "name": "(x: Int)(implicit y: Int, implicit z: Int)Int",
          "paramSections": [
            {
              "params": [
                [
                  "x",
                  {
                    "name": "Int",
                    "fullName": "scala.Int",
                    "typehint": "BasicTypeInfo",
                    "typeId": 14,
                    "typeArgs": [],
                    "members": [],
                    "declAs": {
                      "typehint": "Class"
                    }
                  }
                ]
              ],
              "isImplicit": false
            },
            {
              "params": [
                [
                  "y",
                  {
                    "name": "Int",
                    "fullName": "scala.Int",
                    "typehint": "BasicTypeInfo",
                    "typeId": 14,
                    "typeArgs": [],
                    "members": [],
                    "declAs": {
                      "typehint": "Class"
                    }
                  }
                ],
                [
                  "z",
                  {
                    "name": "Int",
                    "fullName": "scala.Int",
                    "typehint": "BasicTypeInfo",
                    "typeId": 14,
                    "typeArgs": [],
                    "members": [],
                    "declAs": {
                      "typehint": "Class"
                    }
                  }
                ]
              ],
              "isImplicit": true
            }
          ],
          "typehint": "ArrowTypeInfo",
          "typeId": 4367
        },
        "isCallable": true,
        "ownerTypeId": 16
      },
      "funIsImplicit": false,
      "end": 574,
      "start": 564
    }
    result = formatImplicitInfo(input)
    expect(result).toBe("Implicit parameters added to call of curried: (y, y)")



  it "should format implicit conversion", ->
    input =   {
      "typehint": "ImplicitConversionInfo",
      "start": 604,
      "end": 611,
      "fun": {
        "name": "ToApplyOps",
        "localName": "ToApplyOps",
        "declPos": {
          "typehint": "OffsetSourcePosition",
          "file": "/Users/viktor/dev/projects/ensime-test-project/.ensime_cache/dep-src/source-jars/scalaz/syntax/ApplySyntax.scala",
          "offset": 1568
        },
        "type": {
          "resultType": {
            "name": "ApplyOps",
            "fullName": "scalaz.syntax.ApplyOps",
            "typehint": "BasicTypeInfo",
            "typeId": 304,
            "typeArgs": [
              {
                "name": "F",
                "fullName": "scalaz.syntax.F",
                "typehint": "BasicTypeInfo",
                "typeId": 302,
                "typeArgs": [],
                "members": [],
                "declAs": {
                  "typehint": "Nil"
                }
              },
              {
                "name": "A",
                "fullName": "scalaz.syntax.A",
                "typehint": "BasicTypeInfo",
                "typeId": 300,
                "typeArgs": [],
                "members": [],
                "declAs": {
                  "typehint": "Nil"
                }
              }
            ],
            "members": [],
            "declAs": {
              "typehint": "Class"
            }
          },
          "name": "[F[_], A](v: F[A])(implicit F0: scalaz.Apply[F])scalaz.syntax.ApplyOps[F,A]",
          "paramSections": [
            {
              "params": [
                [
                  "v",
                  {
                    "name": "F",
                    "fullName": "scalaz.syntax.F",
                    "typehint": "BasicTypeInfo",
                    "typeId": 299,
                    "typeArgs": [
                      {
                        "name": "A",
                        "fullName": "scalaz.syntax.A",
                        "typehint": "BasicTypeInfo",
                        "typeId": 300,
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
            },
            {
              "params": [
                [
                  "F0",
                  {
                    "name": "Apply",
                    "fullName": "scalaz.Apply",
                    "typehint": "BasicTypeInfo",
                    "typeId": 301,
                    "typeArgs": [
                      {
                        "name": "F",
                        "fullName": "scalaz.syntax.F",
                        "typehint": "BasicTypeInfo",
                        "typeId": 302,
                        "typeArgs": [],
                        "members": [],
                        "declAs": {
                          "typehint": "Nil"
                        }
                      }
                    ],
                    "members": [],
                    "declAs": {
                      "typehint": "Trait"
                    }
                  }
                ]
              ],
              "isImplicit": true
            }
          ],
          "typehint": "ArrowTypeInfo",
          "typeId": 303
        },
        "isCallable": true,
        "ownerTypeId": 34
      }
    }
    result = formatImplicitInfo(input)
    expect(result).toBe("Implicit conversion: ToApplyOps")

  it "should handle FunctionX with arrow notation", ->
    input =
          {
            "name": "Function1",
            "fullName": "scala.Function1",
            "typehint": "BasicTypeInfo",
            "typeId": 4464,
            "typeArgs": [
              {
                "name": "Int",
                "fullName": "scala.Int",
                "typehint": "BasicTypeInfo",
                "typeId": 14,
                "typeArgs": [],
                "members": [],
                "declAs": {
                  "typehint": "Class"
                }
              },
              {
                "name": "Double",
                "fullName": "scala.Double",
                "typehint": "BasicTypeInfo",
                "typeId": 2600,
                "typeArgs": [],
                "members": [],
                "declAs": {
                  "typehint": "Class"
                }
              }
            ],
            "members": [],
            "declAs": {
              "typehint": "Trait"
            }
          }
    result = formatType(input)
    expect(result).toBe("Int => Double")
