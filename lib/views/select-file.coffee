Vue = require('vue')
{addModalPanel} = require('../utils')


# TODO: Look at https://github.com/js-padavan/atom-enhanced-tabs/blob/master/lib/SimpleListView.coffee

module.exports = class SelectDotEnsime
  constructor: (files, onSelect, onCancel = -> ) ->
    vue = new Vue({
      template: """
        <div tabindex="0" id="select-file" class="select-list fuzzy-finder">
          <div>Please choose which Ensime project to start up:</div>
          <ol class="list-group">
            <li v-for="file in files" v-bind:class="{'selected': $index==selected}">
              <div class="primary-line file icon icon-file-text">{{file.path}}</div>
            </li>
          </ol>
        </div>
        """
      data: () ->
        selected: 0
        files: files

      attached: () ->
        console.log("attached called: " + this.$el)

        done = () =>
          @commands.dispose()
          @$emit('done')

        @commands = atom.commands.add window,
          'core:move-up': (event) =>
            if(@selected > 0)
              @selected -= 1
            event.stopPropagation()
          'core:move-down': (event) =>
            if(@selected < files.length - 1)
              @selected += 1
            event.stopPropagation()
          'core:confirm': (event) =>
            selected = files[@selected]
            console.log(["selected: ", selected])
            done()
            onSelect(selected)
            event.stopPropagation()
          'core:cancel': (event) ->
            onCancel()
            done()
            event.stopPropagation()

        @$on 'focusout', () ->
          done()

        console.log("attached finished: " + @$el)
      })

    @container = addModalPanel(vue, true)
    vue.$on 'done', () =>
      @container.destroy()

    vue.$el.focus()
    console.log("vue.el: " + vue.$el)
