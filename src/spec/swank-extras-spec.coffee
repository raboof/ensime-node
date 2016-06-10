lib = '../lib'
{sexpToJObject, arrToJObject} = require "#{lib}/lisp/swank-extras"
{readFromString, fromLisp} = require "#{lib}/lisp/lisp"

describe 'sexpToJObject', ->
  it "should parse the problematic part of completion response", ->

    input = """
    ((("x" "Int") ("y" "Int")))
    """

    lisp = readFromString(input)
    arr = fromLisp(lisp)

    result = arrToJObject(arr)

    expect(result[0][0][0]).toBe("x")
    expect(result[0][1][1]).toBe("Int")

  it "should parse scala notes", ->
    input = """
    (:scala-notes (:is-full nil :notes ((:file "/Users/viktor/dev/projects/kostbevakningen/src/main/scala/se/kostbevakningen/model/record/Ingredient.scala" :msg "missing
     arguments for method test in object Ingredient; follow this method with `_' if you want to treat it as a partially applied function" :severity error :beg 4138 :end 4142 :line 105 :col 3))))
    """

    result = sexpToJObject(readFromString(input))
    expect(result[":scala-notes"][":notes"].length).toBe(1)
