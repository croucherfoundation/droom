## Asset inserter
#
# This view inserts a new asset element into the html stream with a management view wrapped around it.
#
class Ed.Views.AssetInserter extends Ed.View
  template: "ed/inserter"
  tagName: "div"
  className: "ed-inserter"

  ui:
    adders: "a.add"

  events:
    "click a.show": "toggleButtons"
    "click a.image": "addImage"
    "click a.video": "addVideo"
    "click a.quote": "addQuote"
    "click a.button": "addButton"
    "click a.blocks": "addBlocks"

  onRender: () =>
    @_p = null
    permitted_insertions = _ed.config('insertions')
    @ui.adders.each (i, el) =>
      $el = $(el)
      $el.hide() if permitted_insertions.indexOf($el.data('insert')) is -1

  #TODO shouldn't we know about the holding editable so as to tell it about new assets?
  # and also todo: please can we just render this with no special calls?
  attendTo: ($el) =>
    @_target_el = $el
    @$el.appendTo $('body')
    @_target_el.on "click keyup focus", @followCaret

  followCaret: (e)=>
    selection = @el.ownerDocument.getSelection()
    if !selection or selection.rangeCount is 0
      current = $(e.target)
    else
      range = selection.getRangeAt(0)
      current = $(range.commonAncestorContainer)
    @_p = current.closest('p')
    if @_p.length and (@isBlank(@_p.text()) or @_p.text() is "​") # there's a zwsp in the last ""
      @show(@_p)
    else
      @hide()

  toggleButtons: (e) =>
    e?.preventDefault()
    if @$el.hasClass('showing')
      @trigger 'contract'
      @$el.removeClass('showing')
    else
      @trigger 'expand'
      @$el.addClass('showing')

  addImage: =>
    @insert new Ed.Views.Image

  addVideo: =>
    @insert new Ed.Views.Video

  addQuote: =>
    @insert new Ed.Views.Quote

  addButton: =>
    @insert new Ed.Views.Button

  addBlocks: =>
    @insert new Ed.Views.Blocks

  insert: (view) =>
    if @_p
      @_p.before view.el
      # @_p.remove() if @isBlank(@_p.text())
    else
      @_target_el.append view.el
      @_target_el.append $("<p />")
    view.render()
    view.focus?()
    @_target_el.trigger 'input'
    @hide()

  place: ($el) =>
    position = $el.offset()
    @$el.css
      top: position.top - 10
      left: position.left - 32

  show: () =>
    @place(@_p)
    @$el.show()
    @_target_el.parents('.scroller').on 'scroll', => @place(@_p)

  hide: () =>
    @$el.hide()
    @$el.removeClass('showing')
    @_target_el.parents('.scroller').off 'scroll'



## Asset editors
#
# Wrap around an embedded asset to present controls for editing or replacing it.
# The editor is responsible for adding pickers, stylers, importers and so on.
# We also catch some events here and pass them on, so as to present a broad target,
# including click to select and drop to upload.
#
class Ed.Views.AssetEditor extends Ed.View
  defaultSize: "full"
  stylerView: "AssetStyler"
  importerView: "AssetImporter"
  uploaderView: "AssetUploader"

  ui:
    catcher: ".ed-dropmask"
    buttons: ".ed-buttons"
    deleter: "a.delete"

  triggers:
    "click @ui.deleter": "remove"

  events:
    "click @ui.catcher": "closeHelpers"
    "dragenter @ui.catcher": "lookAvailable"
    "dragover @ui.catcher": "dragOver"
    "dragleave @ui.catcher": "lookNormal"
    "drop @ui.catcher": "catchFiles"
    "click @ui.catcher": "pickFile"

  initialize: (opts={}) =>
    @_size ?= _.result @, 'defaultSize'
    if collection_name = @getOption('collectionName')
      @collection = _ed[collection_name]
    super

  onRender: =>
    @log "🚜 onRender", @el
    @$el.attr('data-ed', true)
    @addHelpers()

  addHelpers: =>
    if uploader_view_class_name = @getOption('uploaderView')
      if uploader_view_class = Ed.Views[uploader_view_class_name]
        @_uploader = new uploader_view_class
          collection: @collection
        @_uploader.$el.appendTo @ui.buttons
        @_uploader.render()
        @log "🚜 added uploader in", @_uploader.el
        @_uploader.on "select", @setModel
        @_uploader.on "create", @update
        @_uploader.on "pick", => @closeHelpers()

    if importer_view_class_name = @getOption('importerView')
      if importer_view_class = Ed.Views[importer_view_class_name]
        @_importer = new importer_view_class
          collection: @collection
        @_importer.$el.appendTo @ui.buttons
        @_importer.render()
        @_importer.on "select", @setModel
        @_importer.on "create", @update
        @_importer.on "open", => @closeOtherHelpers(@_importer)

    if picker_view_class_name = @getOption('pickerView')
      if picker_view_class = Ed.Views[picker_view_class_name ]
        @_picker = new picker_view_class
          collection: @collection
        @_picker.$el.appendTo @ui.buttons
        @_picker.render()
        @_picker.on "select", @setModel
        @_picker.on "open", => @closeOtherHelpers(@_picker)

    if _ed.getOption('asset_styles')
      if styler_view_class_name = @getOption('stylerView')
        if styler_view_class = Ed.Views[styler_view_class_name]
          @_styler = new styler_view_class
            model: @model
          @_styler.$el.appendTo @ui.buttons
          @_styler.render()
          @_styler.on "styled", @setStyle
          @_styler.on "open", => @closeOtherHelpers(@_styler)

  ## Selection controls
  #
  setModel: (model) =>
    @model = model
    @_styler?.setModel @model
    @trigger "select", @model

  update: =>
    @trigger 'update'

  ## Styling controls
  #
  setSize: (size) =>
    @_size = size
    @stickit() if @model

  setStyle: (style) =>
    @$el.removeClass('right left full').addClass(style)
    size = if style is "full" then "full" else "half"
    @setSize size
    @update()


  ## Dropped-file handlers
  # Live here so as to be applied to the whole asset element.
  # Dropped file is passed to our uploader for processing.
  #
  dragOver: (e) =>
    e?.preventDefault()
    if e.originalEvent.dataTransfer
      e.originalEvent.dataTransfer.dropEffect = 'copy'

  catchFiles: (e) =>
    @lookNormal()
    if e?.originalEvent.dataTransfer?.files.length
      @containEvent(e)
      @readFile e.originalEvent.dataTransfer.files
    else
      console.log "unreadable drop", e

  readFile: (files) =>
    @_uploader.readLocalFile(files[0]) if @_uploader and files.length

  lookAvailable: (e) =>
    e?.stopPropagation()
    @ui.catcher.addClass('droppable')

  lookNormal: (e) =>
    e?.stopPropagation()
    @ui.catcher.removeClass('droppable')

  ## Click handler
  # allows click anywhere to upload. Event is relayed to uploader.
  #
  pickFile: (e) =>
    e?.preventDefault()
    @_uploader?.pickFile(e)

  ## Menu display

  closeHelpers: =>
    # event allowed through
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close()

  closeOtherHelpers: (helper) =>
    _.each [@_picker, @_importer, @_styler], (h) ->
      h?.close() unless h is helper


class Ed.Views.ImageEditor extends Ed.Views.AssetEditor
  template: "ed/image_editor"
  pickerView: "ImagePicker"
  importerView: "ImageImporter"
  uploaderView: "ImageUploader"
  collectionName: "images"


class Ed.Views.MainImageEditor extends Ed.Views.ImageEditor
  template: "ed/main_image_editor"


class Ed.Views.VideoEditor extends Ed.Views.AssetEditor
  template: "ed/video_editor"
  pickerView: "VideoPicker"
  importerView: "VideoImporter"
  uploaderView: "VideoUploader"
  collectionName: "videos"


class Ed.Views.QuoteEditor extends Ed.Views.AssetEditor
  template: "ed/quote_editor"
  importerView: false
  uploaderView: false


class Ed.Views.ButtonEditor extends Ed.Views.AssetEditor
  template: "ed/button_editor"
  importerView: false
  uploaderView: false


## Asset pickers
#
# Display a list of assets, receive a selection click and call setModel on the Asset container.
#
class Ed.Views.AssetPicker extends Ed.Views.MenuView
  tagName: "div"
  className: "picker"
  listView: "AssetList"

  ui:
    head: ".menu-head"
    body: ".menu-body"
    list: ".pick"
    closer: "a.close"

  onRender: =>
    super
    @setVisibility()
    @collection.on 'add remove reset', @setVisibility

  onOpen: =>
    unless @_list_view
      list_view_class = @getOption('listView')
      @_list_view = new Ed.Views[list_view_class]
        collection: @collection
      @ui.list.append @_list_view.el
      @_list_view.on "select", @selectModel
    @_list_view.render()

  # passed back to the Asset view.
  selectModel: (model) =>
    @close()
    @trigger "select", model

  setVisibility: =>
    if @collection.length
      @$el.show()
    else
      @$el.hide()


class Ed.Views.ImagePicker extends Ed.Views.AssetPicker
  template: "ed/image_picker"
  listView: "ImageList"


class Ed.Views.VideoPicker extends Ed.Views.AssetPicker
  template: "ed/video_picker"
  listView: "VideoList"


## Asset uploaders
#
# Take a file, turn it into an Asset and call setModel on the Asset container.
#
class Ed.Views.AssetUploader extends Ed.View
  template: "ed/asset_uploader"
  tagName: "div"
  className: "uploader"

  ui:
    label: "label"
    filefield: 'input[type="file"]'
    prompt: ".prompt"

  events:
    "click @ui.filefield": "containEvent"
    "change @ui.filefield": "getPickedFile"
    "click @ui.label": "triggerPick"

  ## Picked-file handlers
  #
  # `pickFile` can be called from outside the uploader.
  pickFile: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @trigger 'pick'
    @ui.filefield.click()

  # but triggerPick is called from a real click event, which we allow to continue.
  triggerPick: =>
    @trigger 'pick'

  # then `getPickedFile` is called on filefield change.
  getPickedFile: (e) =>
    if files = @ui.filefield[0].files
      @readLocalFile files[0]

  # `readLocalFile` is called either from here or from the outer Editor on file drop.
  readLocalFile: (file) =>
    if file?
      if problem = @badFile(file)
        @complain problem
      else
        reader = new FileReader()
        reader.onloadend = =>
          @createModel reader.result, file
        reader.readAsDataURL(file)

  createModel: (data, file) =>
    model_data =
      file_data: data
      file_name: file.name
      file_size: file.size
      file_type: file.type
    model = @collection.add model_data, at: 0
    @trigger "select", model
    model.save().done =>
      @trigger "create", model

  containEvent: (e) =>
    e?.stopPropagation()

  badFile: (file) =>
    problem = false
    if size_limit = @getOption('sizeLimit')
      mb = file.size / 1048576
      if mb > size_limit
        nice_size = Math.floor(mb * 100) / 100
        problem = "Sorry: there is a limit of #{size_limit}MB for this type of file and #{file.name} is <strong>#{nice_size}MB</strong>."
    if mime_types = @getOption('permittedTypes')
      unless matchy = _.any(mime_types, (mt) -> file.type.match(mt))
        problem = "Sorry: files of type #{file.type} are not supported here."
    problem


class Ed.Views.ImageUploader extends Ed.Views.AssetUploader
  permittedTypes: ["image/jpeg", "image/png", "image/gif"]
  sizeLimit: 10


class Ed.Views.VideoUploader extends Ed.Views.AssetUploader
  permittedTypes: ["video/mp4", "video/ogg", "video/webm"]
  sizeLimit: 100


  ## Asset importers
  #
  # Take a URL, turn it into an Asset and call setModel on the Asset container.
  #
  class Ed.Views.AssetImporter extends Ed.Views.MenuView
    tagName: "div"
    className: "importer"

    ui:
      head: ".menu-head"
      body: ".menu-body"
      url: "input.remote_url"
      button: "a.submit"
      closer: "a.close"
      waiter: "p.waiter"

    events:
      "click @ui.head": "toggleMenu"
      "click @ui.closer": "close"
      "click @ui.button": "createModel"

    createModel: =>
      if remote_url = @ui.url.val()
        model = @collection.add
          remote_url: remote_url
        @trigger 'select', model
        @disableForm()
        model.save().done =>
          @trigger 'create', model
          @resetForm()
          @close()

    disableForm: =>
      @ui.url.attr('disabled', true)
      @ui.button.addClass('waiting')
      @ui.waiter.show()

    resetForm: =>
      @ui.button.removeClass('waiting')
      @ui.url.removeAttr('disabled')
      @ui.waiter.hide()
      @ui.url.val("")


  class Ed.Views.ImageImporter extends Ed.Views.AssetImporter
    template: "ed/image_importer"


  class Ed.Views.VideoImporter extends Ed.Views.AssetImporter
    template: "ed/video_importer"













## Asset-choosers
#
# The submenu for each asset picker is a chooser-list.
# These are small thumbnail galleries with add and import controls alongside.
#
class Ed.Views.ListedAsset extends Ed.View
  template: "ed/listed"
  tagName: "li"
  className: "asset"

  ui:
    img: 'img'

  events:
    "click a.delete": "deleteModel"
    "click a.preview": "selectMe"

  bindings:
    "a.preview":
      attributes: [
        name: 'style'
        observe: 'icon_url'
        onGet: "backgroundUrl"
      ,
        name: "class"
        observe: "provider"
        onGet: "providerClass"
      ,
        name: "title"
        observe: "title"
      ]
    ".file_size":
      observe: "file_size"
      onGet: "inBytes"
    ".width":
      observe: "width"
      onGet: "inPixels"
    ".height":
      observe: "height"
      onGet: "inPixels"
    ".duration":
      observe: "duration"
      onGet: "inTime"

  onRender: =>
    @stickit()
    @_progress = new Ed.Views.ProgressBar
      model: @model
      size: 40
      thickness: 10
    @_progress.$el.appendTo @$el
    @_progress.render()

  deleteModel: (e) =>
    e?.preventDefault()
    @model.remove()

  selectMe: (e) =>
    e?.preventDefault?()
    @trigger 'select', @model

  backgroundUrl: (url) =>
    if url
      "background-image: url('#{url}')"
    else
      ""


class Ed.Views.NoListedAsset extends Ed.View
  template: "ed/none"
  tagName: "li"
  className: "empty"



class Ed.Views.AssetList extends Ed.CollectionView
  childView: Ed.Views.ListedAsset
  emptyView: Ed.Views.NoListedAsset
  tagName: "ul"
  className: "ed-assets"

  childViewTriggers:
    'select': 'select'


class Ed.Views.ImageList extends Ed.Views.AssetList


class Ed.Views.VideoList extends Ed.Views.AssetList



## Toolbar
#
# Attaches an editing toolbar to a DOM element.
#

class Ed.Views.Toolbar extends Ed.View
  template: _.noop
  className: "ed-toolbar"

  initialize: (opts={}) =>
    @target_el = opts.target

  onRender: () =>
    @_toolbar ?= new MediumEditor @target_el,
      placeholder: false
      autoLink: true
      imageDragging: false
      anchor:
        customClassOption: null
        customClassOptionText: 'Button'
        linkValidation: false
        placeholderText: 'URL...'
        targetCheckbox: false
      anchorPreview: false
      paste:
        forcePlainText: false
        cleanPastedHTML: true
        cleanReplacements: []
        cleanAttrs: ['class', 'style', 'dir']
        cleanTags: ['meta']
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: true
        buttons: [
          name: 'bold'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-bold" viewBox="0 0 16 16">
            <path d="M8.21 13c2.106 0 3.412-1.087 3.412-2.823 0-1.306-.984-2.283-2.324-2.386v-.055a2.176 2.176 0 0 0 1.852-2.14c0-1.51-1.162-2.46-3.014-2.46H3.843V13H8.21zM5.908 4.674h1.696c.963 0 1.517.451 1.517 1.244 0 .834-.629 1.32-1.73 1.32H5.908V4.673zm0 6.788V8.598h1.73c1.217 0 1.88.492 1.88 1.415 0 .943-.643 1.449-1.832 1.449H5.907z"/>
          </svg>'
        ,
          name: 'italic'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-italic" viewBox="0 0 16 16">
            <path d="M7.991 11.674 9.53 4.455c.123-.595.246-.71 1.347-.807l.11-.52H7.211l-.11.52c1.06.096 1.128.212 1.005.807L6.57 11.674c-.123.595-.246.71-1.346.806l-.11.52h3.774l.11-.52c-1.06-.095-1.129-.211-1.006-.806z"/>
          </svg>'
        ,
          name: 'anchor'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-link-45deg" viewBox="0 0 16 16">
            <path d="M4.715 6.542 3.343 7.914a3 3 0 1 0 4.243 4.243l1.828-1.829A3 3 0 0 0 8.586 5.5L8 6.086a1.002 1.002 0 0 0-.154.199 2 2 0 0 1 .861 3.337L6.88 11.45a2 2 0 1 1-2.83-2.83l.793-.792a4.018 4.018 0 0 1-.128-1.287z"/>
            <path d="M6.586 4.672A3 3 0 0 0 7.414 9.5l.775-.776a2 2 0 0 1-.896-3.346L9.12 3.55a2 2 0 1 1 2.83 2.83l-.793.792c.112.42.155.855.128 1.287l1.372-1.372a3 3 0 1 0-4.243-4.243L6.586 4.672z"/>
          </svg>'
        ,
          name: 'orderedlist'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-list-ol" viewBox="0 0 16 16">
            <path fill-rule="evenodd" d="M5 11.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5z"/>
            <path d="M1.713 11.865v-.474H2c.217 0 .363-.137.363-.317 0-.185-.158-.31-.361-.31-.223 0-.367.152-.373.31h-.59c.016-.467.373-.787.986-.787.588-.002.954.291.957.703a.595.595 0 0 1-.492.594v.033a.615.615 0 0 1 .569.631c.003.533-.502.8-1.051.8-.656 0-1-.37-1.008-.794h.582c.008.178.186.306.422.309.254 0 .424-.145.422-.35-.002-.195-.155-.348-.414-.348h-.3zm-.004-4.699h-.604v-.035c0-.408.295-.844.958-.844.583 0 .96.326.96.756 0 .389-.257.617-.476.848l-.537.572v.03h1.054V9H1.143v-.395l.957-.99c.138-.142.293-.304.293-.508 0-.18-.147-.32-.342-.32a.33.33 0 0 0-.342.338v.041zM2.564 5h-.635V2.924h-.031l-.598.42v-.567l.629-.443h.635V5z"/>
          </svg>'
        ,
          name: 'unorderedlist'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-list-ul" viewBox="0 0 16 16">
            <path fill-rule="evenodd" d="M5 11.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm-3 1a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0 4a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0 4a1 1 0 1 0 0-2 1 1 0 0 0 0 2z"/>
          </svg>'
        ,
          name: 'h2'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-h2" viewBox="0 0 16 16">
            <path d="M7.638 13V3.669H6.38V7.62H1.759V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.022-6.733v-.048c0-.889.63-1.668 1.716-1.668.957 0 1.675.608 1.675 1.572 0 .855-.554 1.504-1.067 2.085l-3.513 3.999V13H15.5v-1.094h-4.245v-.075l2.481-2.844c.875-.998 1.586-1.784 1.586-2.953 0-1.463-1.155-2.556-2.919-2.556-1.941 0-2.966 1.326-2.966 2.74v.049h1.223z"/>
          </svg>'
        ,
          name: 'h3'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-h3" viewBox="0 0 16 16">
            <path d="M7.637 13V3.669H6.379V7.62H1.758V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.625-4.272h1.018c1.142 0 1.935.67 1.949 1.674.013 1.005-.78 1.737-2.01 1.73-1.08-.007-1.853-.588-1.935-1.32H9.108c.069 1.327 1.224 2.386 3.083 2.386 1.935 0 3.343-1.155 3.309-2.789-.027-1.51-1.251-2.16-2.037-2.249v-.068c.704-.123 1.764-.91 1.723-2.229-.035-1.353-1.176-2.4-2.954-2.385-1.873.006-2.857 1.162-2.898 2.358h1.196c.062-.69.711-1.299 1.696-1.299.998 0 1.695.622 1.695 1.525.007.922-.718 1.592-1.695 1.592h-.964v1.074z"/>
          </svg>'
        ,
          name: 'removeFormat'
          contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16">
            <path fill-rule="evenodd" d="M13.854 2.146a.5.5 0 0 1 0 .708l-11 11a.5.5 0 0 1-.708-.708l11-11a.5.5 0 0 1 .708 0Z"/>
            <path fill-rule="evenodd" d="M2.146 2.146a.5.5 0 0 0 0 .708l11 11a.5.5 0 0 0 .708-.708l-11-11a.5.5 0 0 0-.708 0Z"/>
          </svg>'
        ]





## Asset styles
#
# All the assets get the same layout options, selected by buttons in this view.

class Ed.Views.AssetStyler extends Ed.View
  tagName: "div"
  className: "styler"
  template: "ed/styler"
  events:
    "click a.right": "setRight"
    "click a.left": "setLeft"
    "click a.full": "setFull"
    "click a.wide": "setWide"
    "click a.hero": "setHero"

  onRender: =>
    if @model
      @$el.show()
    else
      @$el.hide()

  setModel: (model) =>
    @model = model
    @render()

  setRight: => @trigger "styled", "right"
  setLeft: => @trigger "styled", "left"
  setFull: => @trigger "styled", "full"
  setWide: => @trigger "styled", "wide"


class Ed.Views.ImageWeighter extends Ed.Views.MenuView
  tagName: "div"
  className: "weighter"
  template: "ed/weighter"

  ui:
    head: ".menu-head"
    body: ".menu-body"

  events:
    "click @ui.head": "toggleMenu"

  bindings:
    "input.weight": "main_image_weighting"










class Ed.Views.ProgressBar extends Ed.View
  template: _.noop
  tagName: "span"
  className: "ed-progress"

  bindings:
    ":el":
      observe: "progressing"
      visible: true
    ".label":
      observe: "progress"
      update: "progressLabel"

  onRender: () =>
    @initProgress()
    @stickit() if @model
    @model?.on "change:progress", @showProgress

  setModel: (model) =>
    @model = model
    @render()

  initProgress: =>
    @$el.append('<div class="label"></div>')
    @$el.circleProgress
      size: @_size
      thickness: @_thickness
      fill:
        color: "rgba(255,255,255,0.9)"
      emptyFill: "rgba(255,255,255,0.2)"

  showProgress: (model, progress) =>
    @initProgress() unless @$el.data('circle-progress')
    if progress > 1
      @$el.fadeOut(1000)
    else
      @$el.show() unless @$el.is(':visible')
      @$el.circleProgress "value", progress

  progressLabel: ($el, progress, model, options) =>
    if progress > 1
      $el.text("Done")
    else if progress <= 0.99
      $el.text("#{progress * 100}%").removeClass('processing')
    else
      $el.html("please wait").addClass('processing')


class Ed.Views.Helper extends Ed.View
  template: _.noop

  ui:
    shower: "a.show"
    help: ".help"

  events:
    "click a.show": "toggle"

  onRender: =>
    @stickit()

  toggle: (e) =>
    if @$el.hasClass('showing')
      @$el.removeClass 'showing'
    else
      @$el.addClass 'showing'
