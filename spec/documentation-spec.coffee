D = require '../lib/features/documentation'

# Notes:

# 1. The cursor position value corresponds to the chacter it is before
#    E.g., in "import" if the cursor is between "i" and "m", the positon is 1

# 2. ENSIME range should end just beyond the last character.
#    E.g., if "import" is selected, the range is [0, 6]

describe 'Guess the symbol under the cursor', ->
  #                    1         2         3         4         5
  #          012345678901234567890123456789012345678901234567890123456789
  lineDef = "def time(in: InputStream, out: OutputStream): Unit"
  lineVal = "val payload = scala.io.Source.fromInputStream(in).mkString()"

  it "find InputStream with cursor in the middle", ->
    expect(D.guessRange lineDef, 17).toEqual [13, 24]

  it "find InputStream with cursor in the start", ->
    expect(D.guessRange lineDef, 13).toEqual [13, 24]

  it "find InputStream with cursor in the end", ->
    expect(D.guessRange lineDef, 24).toEqual [13, 24]

  it "find Source with cursor in the middle", ->
    expect(D.guessRange lineVal, 25).toEqual [23, 29]

  it "find fromInputStream with cursor in the middle", ->
    expect(D.guessRange lineVal, 36).toEqual [30, 45]

