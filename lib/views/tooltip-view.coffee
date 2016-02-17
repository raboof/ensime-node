    
Template = """
  <div class="ensime-tooltip">
    <div class="ensime-tooltip-inner"></div>
  </div>
"""

# Used for hover for type
class TypeHoverElement extends HTMLElement
  initialize: (text) ->
    @innerHTML = Template
    @container = @querySelector('.ensime-tooltip-inner')
    console.log("@container: " + [@container])
    @container.textContent = text
    this


    
module.exports = TypeHoverElement = document.registerElement('ensime-type-hover-view', {prototype: TypeHoverElement.prototype})
