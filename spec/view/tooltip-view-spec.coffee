TypeHoverElement = require '../../lib/views/tooltip-view'

describe "when we add a tooltip view", ->
  [typeHoverElement] = []
  
  beforeEach ->
    typeHoverElement = new TypeHoverElement()
    jasmine.attachToDOM(typeHoverElement)
    
  it "should be in DOM", ->
    typeHoverElement.initialize("foo")
    console.log(typeHoverElement)
