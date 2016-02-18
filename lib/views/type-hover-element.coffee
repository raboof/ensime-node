    
Template = """
  <div class="ensime-tooltip">
    <div class="ensime-tooltip-inner"></div>
  </div>
"""

# Used for hover for type
class TypeHoverElement extends HTMLElement
  initialize: (html) ->
    @innerHTML = Template
    @container = @querySelector('.ensime-tooltip-inner')
    console.log("@container: " + [@container])
    @container.innerHTML = html
    this


    
module.exports = TypeHoverElement = document.registerElement('ensime-type-hover-view', {prototype: TypeHoverElement.prototype})
