path = require 'path'
fs = require 'fs'


isScalaSource = (editor) ->
  buffer = editor.getBuffer()
  fname = buffer.getUri()
  return path.extname(fname) in ['.scala']

# pixel position from mouse event
pixelPositionFromMouseEvent = (editor, event) ->
  {clientX, clientY} = event
  elem = atom.views.getView(editor)
  linesClientRect = getElementsByClass(elem, ".lines")[0].getBoundingClientRect()
  top = clientY - linesClientRect.top
  left = clientX - linesClientRect.left
  {top, left}

# screen position from mouse event
screenPositionFromMouseEvent = (editor, event) ->
  atom.views.getView(editor).component.screenPositionForMouseEvent event
  # This was broken:
  #editor.screenPositionForPixelPosition(pixelPositionFromMouseEvent(editor, event))

# from haskell-ide
bufferPositionFromMouseEvent = (editor, event) ->
  editor.bufferPositionForScreenPosition (screenPositionFromMouseEvent(editor, event))

getElementsByClass = (elem,klass) ->
  elem.rootElement.querySelectorAll(klass)

devMode = atom.config.get('Ensime.devMode')

log = (toLog) ->
  if devMode
    console.log(toLog.toString())

modalMsg = (title, msg) ->
  atom.confirm
    message: title
    detailedMessage: msg
    buttons:
      Ok: ->

addModalPanel = (vue, visible = false) ->
  # element = document.createElement('div')
  vue.$mount()
  modalPanel = atom.workspace.addModalPanel
        item: vue.$el, visible: visible
  # element
  vue.$el




withSbt = (callback) =>
  sbtCmd = atom.config.get('Ensime.sbtExec')
  if sbtCmd
    callback(sbtCmd)
  else
    # TODO: try to check if on path, can we do this with fs?
    dialog = remote.require('dialog')
    dialog.showOpenDialog({title: "Sorry, but we need you to point out your SBT executive", properties:['openFile']}, (filenames) =>
        sbtCmd = filenames[0]
        atom.config.set('Ensime.sbtExec', sbtCmd)
        callback(sbtCmd)
      )





module.exports = {
  isScalaSource,
  pixelPositionFromMouseEvent,
  screenPositionFromMouseEvent,
  bufferPositionFromMouseEvent,
  getElementsByClass,
  log,
  modalMsg,
  withSbt,
  addModalPanel
}
