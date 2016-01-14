# Atom Ensime

[![Join the chat at https://gitter.im/ensime/ensime-atom](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ensime/ensime-atom?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This is a work in progress to try to use [Ensime](https://github.com/ensime/) functionality in [Atom](https://atom.io)
Way early still and will most likely be very buggy. Or maybe not start at all. Please try it out, be patient and report any issues!

## Prerequisites
- sbt (used to bootstrap server)
- [.ensime file. generate with sbt gen-ensime](https://github.com/ensime/ensime-emacs/wiki/Quick-Start-Guide#installing-the-ensime-sbt-plugin)

## Getting started
- Open a project with a .ensime in root
- Make sure to put path of sbt in settings.
- cmd-shift-P Ensime: Start.
- Then you can use the features marked x below :)

## Complementing packages
### Automatically installed:
- [language-scala](https://atom.io/packages/language-scala) for syntax highlighting.
- [hyperclick](https://atom.io/packages/hyperclick) for code navigation. Ensime hooks in as provider.

### Recomended:
- [Project manager](https://github.com/danielbrodin/atom-project-manager) is really handy to keep track of projects.
- Need plugin to navigate back to last cursor position when "code surfing". Maybe https://atom.io/packages/last-cursor-position

## Features:
- [x] Jump to definition (cmd-click or f4)
- [x] Hover for type info
- [x] Errors and warnings (Cmnds for typecheck file, typecheck buffer, typecheck all). Also setting for typecheck current file on save or while typing.
- [x] Basic autocompletion
- [x] Format source file
- [x] mark applied implicits (conversions and params)
- [x] show applied implicits
- [x] Goto type by simple typing prefix (like cmd-N in Idea or cmd-shift-T in Eclipse?)
- [x] Organize imports
- [ ] Import type at point
- [x] Better errors and warnings with markings in gutter
- [ ] "explicify" applied implicits
- [ ] Find all subclasses of the class under the cursor
- [ ] Find all usages of the function under the cursor

- [ ] _insert your suggestion_


## Dev
- checkout from git straight into .atom/packages (or ln -s). Need to have the right name on the folder: "Ensime".
- run apm install
- "Window: reload" (ctrl-option-cmd l) to reload plugin from source while developing
- In developer tools: `client = atom.packages.getActivePackage('Ensime').mainModule.client`
  client.getImportSuggestions('ApiLogRequest')


## Discuss:
https://groups.google.com/forum/#!searchin/ensime/log/ensime/1dWUQwnFoyk/0O12KPjaIBgJ
https://gitter.im/ensime/ensime-atom

## Technical TODO:
- [x] checkout typescript plugin for hover for type info
- [x] option to start server detached for ease of debugging: https://nodejs.org/api/child_process.html#child_process_options_detached
- [x] update server log in a panel in atom
- [x] Use port file to check for running server
- [x] Remove "start-server" and let init do it all
- [x] EditorControl leaks and keeps swank client on stop. Fix some cleanup!
- [x] Remove flowController-thing and look at Haskell IDE.
- [x] Make "start ensime" to start server(maybe) and client and "stop ensime" kill both
- [x] setting for typechecking current file: ask, on save, while typing + delay ms setting
- [x] only try start server if no port-file
- [x] put console logging under dev-flag or just move to separate log
- [x] Handle types of autocompletion. Weird swank?
- [x] TEEEESTS! Mostly because turnaround is killing me
- [x] re-insert activation events when this hits https://github.com/atom/settings-view/pull/371
- [x] Make update of server implicit from startup'
- [x] Seems we're dependent on language-scala package. At least code-links doesn't seem to realize .scala are source.scala)
- [x] ditch swank for jerk
- [x] Setting for autocomplete - "excludeLowerPriority"
- [x] Autocomplete: :type-sig (((("x" "Int") ("y" "Int"))) "Int")
- [x] Separate each feature in own Editor Controller?
- [x] See if we can use code-links for mouse clicks https://atom.io/packages/code-links (Not gonna do it)
- [x] Check if we can get rid of terminal escape stuff from log. Look at term2 or ask.
- [x] getPath is deprecated: https://github.com/atom/atom/blob/master/src/project.coffee#L471 Maybe need to ask about where .ensime is like Emacs.
- [x] Multiple instances - BIG REFACTORING
- [ ] Really need to lookup instances out of source folder from .ensimes. Just path prefix against project folder doesn't work since sbt meta project typically resides inside.
- [ ] Hook to switch out bottom pane on change of text editor
- [ ] Start/stop ui with server/client info
- [ ] Don't use jquery lookup for https://github.com/atom/status-bar
- [ ] Listen to editors and add custom attribute per instance. https://atom.io/docs/api/v1.2.4/CommandRegistry#instance-add. Then we probably can add commands for just those editors?
- [ ]
- [ ] Use path.dirname(module.filename) instead of package name lookup? https://github.com/paulpflug/vue-hello-world/blob/master/lib/vue-hello-world.coffee#L31
- [ ] Use .vue https://github.com/vuejs/vueify#compiler-api
- [ ] If error with "not found" -> alt-enter for quick import just like idea
- [ ] Check out https://github.com/OmniSharp/omnisharp-atom Seems we can learn a lot!
- [ ] Wait for analyzer ready msg - (:return (:abort 209 "Analyzer is not ready! Please wait.") 4)
- [ ] server will stop logging when atom is reloaded since stdio is piped via node. Pipe to file directly from process
 and tail -f to buffer in atom?
- [ ] add a bottom panel with tabs (one for errors/warnings, one for server log maybe)
- [ ] Look how https://github.com/OmniSharp/omnisharp-atom/wiki makes autocomplete and linter install automatically
- [ ] Rewrite core parts in scala.js, reuse msg classes from ensime and so forth. Make atom interface for scala.js.
- [ ] Someday it would be cool to not use exploded single tree for dep-src so that one have more control like "open on github" of ensime: 404: https://github.com/xebia/cakemix/blob/master/.ensime_cache/dep-src/source-jars/scala/concurrent/duration/package.scala#L17


## Inspiration (steal if you can)
- https://github.com/lukehoban/atom-ide-flow/
- code-links
- https://github.com/atom/atom/blob/master/src/text-editor-component.coffee#L365
- https://github.com/TypeStrong/atom-typescript/
- https://github.com/chaika2013/ide-haskell/

## Links
- https://github.com/ensime/
- Protocol: https://github.com/ensime/ensime-server/blob/master/swank/src/main/scala/org/ensime/server/protocol/swank/SwankProtocol.scala
- Emacs command ref: https://github.com/ensime/ensime-server/wiki/Emacs-Command-Reference
- Ensime google group: https://groups.google.com/forum/#!forum/ensime
- Startup of server from Emacs https://github.com/ensime/ensime-emacs/blob/master/ensime-startup.el
- Space pen https://github.com/atom/space-pen/blob/master/src/space-pen.coffee
- Space pen views https://github.com/atom/atom-space-pen-views/blob/master/src/scroll-view.coffee
- Find and replace:https://github.com/atom/find-and-replace/blob/master/lib/project/results-pane.coffee
