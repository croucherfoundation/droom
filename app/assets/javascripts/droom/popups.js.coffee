jQuery ($) ->

  ## Popups
  #
  # This is the modal overlay we use for most creation and editing tasks. No special setup is required: any link can
  # be turned into a popup-form-generator just by calling
  #
  #   $(link).popup()
  #
  # Display of the popup form is handled by the Popup class. The requests involved in retrieving, submitting and 
  # resubmitting the form are built on the usual `remote` method, which just configures the rails_ujs remote links. 
  # All this is held together by callbacks triggered in the remote_link mechanism. The callbacks are defined anonymously
  # as part of the `$().popup()` method below.
  #
  # We don't attempt to update the page directly with a server response, but a `data-affected` attribute can be used to 
  # trigger a refresh event on any DOM element that should be updated after this action completes. If those elements
  # have (or are within) refreshable behaviour, they will be updated from the server. See 'affecting the page' above.
  #
  $.fn.popup = () ->
    @each ->
      new Popup(@)

  class Popup
    constructor: (element) ->
      @_link = $(element)
      @_iteration = 0
      @_affected = @_link.data('affected')
      @_replaced = @_link.data('replaced')
      @_removed = @_link.data('removed')
      @_aftered = @_link.data('appended')
      @_befored = @_link.data('prepended')
      @_reporter = @_link.data('reporter')
      @_style = @_link.data('style')
      @_delay = @_link.data('delay')
      @_masked = not @_link.data('unmasked')
      @_link.remote
        on_request: @begin
        on_success: @receive

    begin: (event, xhr, settings) =>
      switch @_iteration
        when 0
          @prepare()
        when 1
          # a popup that it is still displaying the first response will just be shown again.
          # edit: after revo changes I don't think this is true any more: popup is reset on close.
          @show()
          return false
        else
          # A popup that is on a second or later response will be considered abandoned and started again.
          @reset()
          @prepare()

    getContainer: () =>
      container = $('<div class="popup" />')
      container.addClass(@_style) if @_style
      container

    prepare: () =>
      body = $('body')
      if @_masked
        @_mask = $('<div class="mask" />').appendTo(body)
      @_container ?= @getContainer()
      @_container.bind 'close', @reset #instead of @hide, @reset is used
      @_container.bind 'finished', @conclude
      @_container.bind 'resize', @place
      @_container.appendTo(body).hide()

    receive: (e, data) =>
      e?.stopPropagation()
      if @_iteration == 0 || $(data).find('form:not(#edit_cell)').not('.button_to').length
        @display(data)
      else
        @conclude(data)

    display: (data) =>
      @_iteration++
      @_content = $(data)
      @_container.empty()
      @_container.append(@_content)
      @_content.activate()
      @show()
      @_header = @_content.find('.header')
      @_content.find('form').remote
        on_cancel: @reset
        on_success: @receive
      @_content.find('a.popup ').remote
        on_cancel: @reset
        on_success: @receive

    conclude: (data) =>
      if @_affected
        aff = $(@_affected)
        if @_delay
          _.delay ->
            aff.trigger "refresh"
          , @_delay
        else
          aff.trigger "refresh"
      if @_aftered?
        addition = $(data)
        $(@_aftered).after(addition)
        addition.activate().signal_confirmation()
      if @_befored?
        addition = $(data)
        $(@_befored).before(addition)
        addition.activate().signal_confirmation()
      if @_removed?
        $(@_removed).remove()
      if @_replaced?
        replacement = $(data)
        $(@_replaced).after(replacement)
        $(@_replaced).remove()
        replacement.activate().signal_confirmation()
      if @_reporter?
        $(@_reporter).html(data).show().signal_confirmation().delay(5000).slideUp()
      @reset()

    show: (e) =>
      e.preventDefault() if e
      @place()
      unless @_container.is(":visible")
        @_container.fadeTo 'fast', 1, () =>
          @_container.find('[autofocus]').focus()
        if @_masked
          @_mask.addClass('up')
          @_mask.bind "click", @hide
          $('#droom').addClass('masked')
        $(window).bind "resize", @place
        @focus()

    hide: (e) =>
      e.preventDefault() if e
      @_container.fadeOut('fast')
      if @_masked
        @_mask.removeClass('up')
        @_mask.unbind "click", @hide
        $('#droom').removeClass('masked')
      $(window).unbind "resize", @place

    reset: () =>
      @hide()
      @_container.remove()
      @_mask?.remove()
      @_iteration = 0

    place: (e) =>
      if $('body').hasClass('mobile')
        @_container.css
          top: 0
          left: 0

      else
        width = @_container.children().first().width() || 580
        w = $(window)
        height_limit = w.height() - 100
        height = [@_container.height(), height_limit].min()
        if pos = @_container.data('droom-positioned')
          placement = 
            left: pos.left + window.pageXOffset
            top: pos.top + window.pageYOffset
            width: width
            "max-height": height_limit
        else
          left = parseInt((w.width() - width) / 2) + window.pageXOffset
          top = parseInt((w.height() - height - 40) / 2) + window.pageYOffset
          placement = 
            left: left
            top: top
            width: width
            "max-height": height_limit
        if @_container.is(":visible")
          @_container.animate placement
        else
          @_container.css placement

    focus: () =>
      @_container.find('[autofocus]').focus()



  # The action menu is a simple popup submenu used to hide editing links.
  #
  $.fn.action_menu = ->
    @each ->
      new ActionMenu(@)
    @

  class ActionMenu
    @menus: $()
    @remember: (menu) ->
      @menus.push(menu)
    @hideAll: () ->
      menu.hide() for menu in @menus

    constructor: (element) ->
      @_link = $(element)
      @_selector = "[data-for=\"#{@_link.attr('data-menu')}\"]"
      @_link.click @toggle
      ActionMenu.remember(@)

    place: =>
      pos = @_link.position()
      $(@_selector).css
        top: pos.top + 20
        left: pos.left

    toggle: (e) =>
      if e
        e.preventDefault() 
        e.stopPropagation()
      if @_link.hasClass('up') then @hide() else @show()

    show: (e) =>
      @place()
      ActionMenu.hideAll()
      @_link.addClass('up')
      $(@_selector).first().stop().slideDown 'fast'
      $(document).bind "click", @hide
    
    hide: (e) =>
      $(@_selector).first().stop().slideUp 'fast', () =>
        @_link.removeClass('up')
      $(document).unbind "click", @hide



  class Panel
    @panels: $()
    @remember: (panel) ->
      @panels.push(panel)
    @hideAll: () ->
      panel.hide() for panel in @panels

    constructor: (element) ->
      console.log "panel", element
      @container = $(element)
      @id = @container.attr('data-panel')
      @links = $("a[data-panel='#{@id}']")
      @header = $("a[data-panel='#{@id}']")
      @closer = @container.find('a.close')
      box = @header.offsetParent()
      @container.appendTo(box)
      @patch = $('<div class="patch" />').appendTo(box)
      @timer = null
      @showing = false

      # Open on hover or click. Close with wobble catcher on exit. 
      @links.bind "click", @toggle
      @links.bind "touchstart", @showOrGo
      $(@header).hover(@show, @hideSoon)
      $(@patch).hover(@show, @hideSoon)
      $(@container).hover(@show, @hideSoon)

      # To open remotely just trigger a show event on the panel.
      @container.bind "show", @show
      @container.bind "hide", @hide
      @closer.bind "click", @hide
      @set()
      Panel.remember(@)

    setup: () =>
      unless $('body').hasClass('mobile')
        position = @header.position()
        offset = @header.offset()
        top = position.top + @header.outerHeight()
        @patch.css
          left: position.left + 1
          top: top - 3
          width: @header.outerWidth() - 2
        @container.css
          right: 0
          top: top - 1

    set: () =>
      if @header.hasClass('here') then @show() else @hide()
      
    toggle: (e) =>
      if e
        e.preventDefault()
        e.stopPropagation()
      if @showing then @hide() else @show()
    
    # We hit this method on click or touchstart. It has two purposes: to prevent annoying hover-based double taps,
    # and to allow a click on the menu header *while it is showing* (probably because of a hover event) to activate the underlying link.
    #
    showOrGo: (e) =>
      unless @showing
        if e
          e.preventDefault()
          e.stopPropagation()
        @show()

    hide: (e) =>
      window.clearTimeout @timer
      @container.removeClass('up')
      @patch.removeClass('up')
      @header.removeClass('up')
      @showing = false

    hideSoon: () =>
      @timer = window.setTimeout @hide, 500

    show: (e) =>
      window.clearTimeout @timer
      unless @showing
        @setup()
        Panel.hideAll()
        @container.addClass('up')
        @patch.addClass('up')
        @header.addClass('up')
        @showing = true
        @container.find('input[autofocus]').get(0)?.focus()

    revert: (e) =>
      Panel.hideAll()


  $.fn.panel = ->
    @each ->
      new Panel(@)
    @

