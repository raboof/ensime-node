Vue = require('vue')
TextEditorVue = require('./small-text-editor-vue')

# TODO: Remove fuzz-finder style and copy to ensime namespace

module.exports = PublicSymbolSearchVue = Vue.extend({
  # https://github.com/atom/atom/blob/master/src/text-editor-component.coffee
  template: """
    <div class="select-list fuzzy-finder">
      <small-text-editor v-ref:editor :text.sync="searchText"></small-text-editor>
      <ol class="list-group">
        <li class="two-lines" v-for="symbol in results" v-bind:class="{'selected': $index==selected}">
          <div class="primary-line file icon icon-file-text">{{symbol.localName}}</div>
          <div class="secondary-line path no-icon">{{symbol.name}}</div>
        </li>
      </ol>
    </div>
    """

  data: () ->
    results: []
    selected: 0
    searchText: ''

  components:
    'small-text-editor': TextEditorVue

  methods:
    onSearchTextUpdated: (callback) ->
      @watcher = @$watch('searchText', callback)
      # TODO: kill of watcher when unmounted?

    focusSearchField: () ->
      @$refs.editor.$el.focus()

    getSelected: () ->
      @results[@selected]
})
