{CompositeDisposable} = require 'atom'
_ = require 'lodash'
{formatImplicitInfo} = require '../formatting'

ListTemplate = """
  <div class="list-scroller">
    <ol class="list-group"></ol>
  </div>
"""


ItemTemplate = """
  <span class="info"></span>
  """

class ImplicitInfoView extends HTMLElement

  createdCallback: ->
    @renderList()
    @subscriptions = new CompositeDisposable
    @classList.add('popover-list', 'select-list')

  attachedCallback: ->
    # @parentElement.classList.add('implicit-infos')
    @addActiveClassToEditor()

  renderList: ->
    @innerHTML = ListTemplate
    @ol = @querySelector('.list-group')

  initialize: (@model) ->
    return unless @model?
    @subscriptions.add @model.onDidDispose(@dispose.bind(this))
    for info, index in @model.infos
      @renderItem(info, index)
    this

  renderItem: (info, index) ->
    li = @ol.childNodes[index]
    unless li
      li = document.createElement('li')
      li.innerHTML = ItemTemplate
      li.dataset.index = index
      @ol.appendChild(li)
    wordSpan = li.querySelector('.info')
    wordSpan.innerHTML = "<span>#{@renderInnerText(info)}</span>"


  renderInnerText: (info) ->
    formatImplicitInfo(info)



  addActiveClassToEditor: ->
    editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
    editorElement?.classList?.add 'ensime-implicits-active'

  removeActiveClassFromEditor: ->
    editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
    editorElement?.classList?.remove 'ensime-implicits-active'

  dispose: ->
    @subscriptions.dispose()
    @parentNode?.removeChild(this)

module.exports = ImplicitInfoView = document.registerElement('implicit-info', {prototype: ImplicitInfoView.prototype})
