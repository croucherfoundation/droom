# This is a collection of useful interface behaviours. Most of them are form- or input-based. They shouldn't ever
# be object-specific, but can be used throughout the droom interface to make forms and other controls more lively.
#
# The basic approach here is PJAX: our remote calls always return chunks of html. There are no client-side templates
# or model classes. Instead we have defined a set of actions, by which page elements can interact with the server in
# structured ways. A tag will declare that it triggers an action, and may also declare that the action will replace or
# affect other elements.
#
# Many elements are refreshable, and an action that affects them will trigger their refreshment. Editing an event is
# a simple remote form operation with several consequences for the page:
#
#   link_to t(:edit_event), edit_event_url(event), :class => 'edit minimal', :data => {
#      :action => "popup",
#      :replaced => "#event_#{event.id}",
#      :affected => ".minimonth"
#   }
#
# When the `popup` action is complete - that is, the server returns a response with no form in it - the final response
# will replace the original event container and the small calendar display will be refreshed to show the possibly revised
# date of the event.
#
# With any luck this simple non-architecture will make it easy to support a future pub-sub update.

jQuery ($) ->

  ## Affecting the page
  #
  # refreshable, affected rules, etc.

  $.fn.refresher = ->
    @each ->
      new Refresher @

  $.fn.refresh = ->
    @trigger('refresh')


  class Refresher
    constructor: (element) ->
      @_container = $(element)
      @_url = @_container.attr('data-refreshing') or @_container.attr('data-url')
      @_method = @_container.attr 'data-method'
      @_data = @_container.attr 'data-params'
      @_container.bind "refresh", @refresh

    refresh: (e) =>
      if e
        e.stopPropagation()
        e.preventDefault()

      if @_url
        @_container.addClass('working')
        params =
          dataType: "html"
          beforeSend: @prep
          success: @replace
        if @_method
          params.method = @_method
          if @_method.toLowerCase() is 'post' and @_data
            params.data = @_data
        $.ajax @_url, params
      else
        console.error "Cannot refresh: no URL to fetch"

    prep: (xhr, settings) =>
      xhr.setRequestHeader('X-PJAX', 'true')
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
      @_container.addClass('waiting')
      true

    replace: (data, textStatus, jqXHR) =>
      replacement = $(data)
      old_container = @_container
      old_container.fadeOut 'fast', () =>
        replacement.hide().insertAfter(old_container)
        old_container.hide()
        replacement.show()
        old_container.trigger 'refreshed', @_container
        old_container.remove()
        replacement.activate().signal_confirmation()
        @_container = replacement


  # ## Actions
  #
  # The 'remove' action takes out the parent element of this node designated by the usual 'affected'
  # attribute. The delete link next to an event, for example:
  #
  #   link_to t(:remove), event_url(event), :method => 'delete', :data => {
  #     :confirm => t(:confirm_delete_event, :name => event.name),
  #     :removes => ".holder",
  #     :affected => ".minimonth"}
  #
  # ...will (on success) remove the first containing '.holder' element and also refresh the mini calendar display.
  #
  $.fn.removes = () ->
    @each ->
      removed = $(@).attr('data-removed') || ".holder"
      affected = $(@).attr('data-affected')
      $(@).remote
        on_success: (response) =>
          if $(@).parents('.menu').first().length == 1
            $(@).parents('.menu').first().fadeOut 'fast', () ->
            $(removed).remove()
          else
            $(@).parents(removed).first().fadeOut 'fast', () ->
              $(@).remove()
              $(affected).trigger "refresh"


  # The 'remove_all' action takes out on success anything matching the given selector:
  #
  #   link_to t(:remove), service_url(service), :method => 'delete', :data => { :removes => "s_#{service.id}" }
  #
  # ...on success takes out every DOM element with the class "s_1".
  #
  $.fn.removes_all = () ->
    @each ->
      removed = $(@).attr('data-removed')
      affected = $(@).attr('data-affected')

      $(@).remote
        on_success: (response) =>
          $(removed).fadeOut 'fast', () ->
            $(@).remove()
            $(affected).trigger "refresh"


  $.fn.affects = () ->
    @each ->
      affected = $(@).attr('data-affected')
      $(@).remote
        on_success: (response) =>
          $(affected).trigger "refresh"


  # Close links work just by triggering a 'hide' event and hoping that something further up the tree will bind
  # it to the right thing.

  $.fn.closes = () ->
    @click (e) ->
      e.preventDefault()
      $(@).trigger('close')


  # *replace_with_remote_content* is a useful shortcut for links and forms that should simply be replaced with the
  # result of their action. Pass force: true to make the replacement immediately upon load. Can be useful for personalisation.
  #
  $.fn.replace_with_remote_content = (selector, opts) ->
    selector ?= '.holder'
    options = $.extend { force: false, confirm: false, slide: false, pjax: true, credentials: false }, opts
    @each ->
      $el = $(@)
      container = $el.attr('data-replaced') || selector
      affected = $el.attr('data-affected')
      $el.remote
        credentials: options.credentials
        pjax: options.pjax
        on_success: (e, response) =>
          response ?= e
          replaced = if container is "self" then $el else $el.self_or_ancestor(container).last()
          replacement = $(response).insertAfter(replaced)
          console.log 'response', response
          console.log 'replaced', replaced
          console.log 'replacement', replacement
          replaced?.remove()
          replacement.activate()
          replacement.hide().slideDown() if options.slide
          replacement.signal_confirmation() if options.confirm
          replacement.trigger('updated')
          $(affected).trigger('refresh')
      if options.force
        $.rails.handleRemote($el)


  # *update_main_content* is used in services page, action from popup and effected on main content
  $.fn.update_main_content = (selector, opts) ->
    selector ?= '.holder'
    options = $.extend { force: false, confirm: false, slide: false, pjax: true, credentials: false }, opts
    @each ->
      $el = $(@)
      container = selector
      $el.remote
        credentials: options.credentials
        pjax: options.pjax
        on_success: (e, response) =>
          response ?= e
          className = $(response).attr "class"
          id = $(response).attr "id"
          @_selector = $("[data-menu=\"#{id}\"]")
          $(@_selector).removeClass().addClass(className)
          $(".menu").hide()


  # The reinviter is an ordinary remote link.
  #
  $.fn.reinviter = ->
    @each ->
      $el = $(@)
      $el.data 'method', 'put'
      $el.remote
        on_request: () =>
          $el.addClass('waiting')
        on_success: (e, r) =>
          $el.removeClass('waiting').addClass('reinvited')
          $el.find('svg use').attr('xlink:href', '#tick_symbol')
          if confirmation = $el.data('confirmation')
            $el.find('span.label').text(confirmation )
        on_error: (xhr, status, error) ->
          $el.removeClass('waiting')
          $el.addClass('erratic')
          $el.find('span.label').text(error)


  # The submitter is a self-disabling submit button that can only be clicked once.
  #
  $.fn.submitter = ->
    @each ->
      button = $(@)
      button.parents('form').bind "submit", (e) ->
        button.addClass('waiting').text('Please wait').bind "click", (e) =>
          e.preventDefault() if e

  $.fn.appends_fields = (appended) ->
    @each ->
      $link = $(@)
      affected = appended ? $link.attr('data-affected')
      limit = parseInt($link.attr('data-limit') || 0)
      set_visibility = () ->
        counter = $(affected).find('fieldset.repeating').length
        if limit and counter >= limit
          $link.hide()
        else
          $link.show()
      set_visibility()
      $link.remote
        on_request: (e, xhr, settings) =>
          $link.addClass('working')
        on_error: () =>
          $link.removeClass('working').addClass('erratic')
        on_success: (e, response) =>
          unless response
            response = e
            e = undefined
          e?.stopPropagation()
          $link.removeClass('working')
          counter = $(affected).find('fieldset').length
          if offset = $(affected).data('offset')
            counter += parseInt(offset)
          addition = $(response.replace(/field_counter/g, counter))
          addition.hide().appendTo(affected).slideDown('fast')
          addition.activate()
          addition.trigger('appended', addition)
          set_visibility()


  $.fn.removes_fields = () ->
    @each ->
      clipper = $(@)
      selector = clipper.attr('data-holder') ? '.holder'
      clipper.bind 'click', (e) ->
        e.preventDefault()
        holder = clipper.parents(selector).first()
        holder.slideUp 'fast', () ->
          delete_field = holder.find('input[data-role="destroy"]')
          if delete_field.length
            delete_field.val(1)
            holder.find('input[type="file"]').disable()
          else
            holder.remove()


  # The setter action sets a single boolean object property by PUTting a single parameter to the link href.
  # :property and :url data- attributes are required. True/false state is signalled by yes/no css class that
  # presumably also affects apperance.
  #
  # As usual success can trigger the refreshment of other elements selected by the data-affected attribute.
  #
  #   %a{:data => {:action => 'setter', :property => 'featured', url: "/api/threads/27/posts/32"}}
  #
  # will toggle on and off the 'featured' property of the resource at that address.
  #
  $.fn.setter = () ->
    @each ->
      new Setter(@)

  class Setter
    constructor: (element, @_root, @_property) ->
      @_link = $(element)
      @_root ?= @_link.attr('data-object')
      @_property ?= @_link.attr('data-property')
      @_positive = @_link.attr('data-positive') ? true
      @_negative = @_link.attr('data-negative') ? false
      @_affected = @_link.attr('data-affected')
      @_link.bind "click", @toggle

    data: (e) =>
      data = {}
      value = if @_link.hasClass('yes') then @_negative else @_positive
      data[@_root] = {}
      data[@_root][@_property] = value
      data['_method'] = "PUT"
      data

    toggle: (e) =>
      e.preventDefault() if e
      value = !@_link.hasClass('yes')
      data = {}
      @_link.addClass('waiting')
      $.ajax
        url: @_link.attr('href')
        type: "POST"
        data: @data()
        success: @update
        error: @error

    error: (xhr, status, error) =>
      @_link.removeClass('waiting').signal_error()

    update: (response) =>
      @_link.removeClass('waiting')
      if @_link.hasClass('yes')
        @_link.addClass('no').removeClass('yes')
      else
        @_link.addClass('yes').removeClass('no')
      $(@_affected).refresh()



  # The toggle action shows or hides the affected elements with cookie-based persistence across page
  # views. A link like this:
  #
  #   %a{:data => {:action => 'toggle', :affected => '.admin'}}
  #
  # will toggle on and off the display of anything with the 'admin' class.
  #
  $.fn.toggle_visibility = () ->
    @each ->
      new Toggle(@, $(@).attr('data-affected'))

  #todo: make this a more versatile base class
  class Toggle
    constructor: (element, @_selector, @_name) ->
      @_container = $(element)
      @_remembered = @_container.attr('data-remembered') != 'false'
      @_name ?= "droom_#{@_selector}_state"
      @_showing_text = @_container.text().replace('show', 'hide').replace('Show', 'Hide').replace('more', 'less').replace('More', 'Less')
      @_hiding_text = @_showing_text.replace('hide', 'show').replace('Hide', 'Show').replace('less', 'more').replace('Less', 'More')
      @_container.click @toggle
      if @_remembered and cookie = $.cookie(@_name)
        @_showing = cookie is "showing"
        @apply()
      else
        @_showing = $(@_selector).is(":visible")
        @store()

    apply: (e) =>
      e.preventDefault() if e
      if @_showing then @show() else @hide()

    toggle: (e) =>
      e.preventDefault() if e
      if @_showing then @slideUp() else @slideDown()

    slideDown: =>
      @_container.addClass('showing')
      $(@_selector).slideDown () =>
        @show()
        @_container.trigger('toggled')

    show: =>
      $(@_selector).show()
      @_container.addClass('showing')
      @_container.text(@_showing_text)
      @_showing = true
      @store()

    slideUp: =>
      $(@_selector).slideUp () =>
        @hide()
        @_container.trigger('toggled')

    hide: =>
      $(@_selector).hide()
      @_container.removeClass('showing')
      @_container.text(@_hiding_text)
      @_showing = false
      @store()

    store: () =>
      if @_remembered
        value = if @_showing then "showing" else "hidden"
        $.cookie @_name, value,
           path: '/'


  # The collapser is a self-expanding unit. Basically, a toggle. #todo: amalgamate!

  $.fn.collapser = (options) ->
    @each ->
      new Collapser(@, options)
    @

  class Collapser
    constructor: (element, opts) ->
      @container = $(element)
      @options = $.extend {
        toggle: "a.name"
        body: ".detail"
        preview: ".preview"
      }, opts
      @id = @container.attr('id')
      @switch = @container.find(@options.toggle)
      @body = @container.find(@options.body)
      @preview = @container.find(@options.preview)
      @switch.click @toggle
      @set()

    set: () =>
      if @container.hasClass("open") then @show() else @hide()

    toggle: (e) =>
      e.preventDefault() if e
      if @container.hasClass("open") then @hide() else @show()

    hide: () =>
      @container.removeClass('open')
      @preview.show().css('position', 'relative')
      @body.stop().slideUp
        duration: 'slow'
        easing: 'glide'
        complete: =>
          @body.hide()

    show: () =>
      @container.addClass('open')
      @preview.css('position', 'absolute')
      @body.stop().slideDown
        duration: 'normal'
        easing: 'boing'
        complete: =>
          @preview.hide().css('position', 'relative')


  # this one just shows or hides based on whether a checkbox is checked

  $.fn.reveals = () ->
    @each ->
      new Revealer(@)

  class Revealer
    constructor: (element) ->
      @_input = $(element)
      @_affected = @_input.attr('data-affected')
      @_converse = @_input.attr('data-converse')
      @_input.bind "click", @set
      @set()

    set: () =>
      if @_input.is(":checked") then @show() else @hide()

    show: (e) =>
      $(@_affected).stop().slideDown()
      $(@_affected).find('input').attr('disabled', false)
      $(@_converse).stop().slideUp()
      $(@_converse).find('input').attr('disabled', true)

    hide: (e) =>
      $(@_affected).stop().slideUp()
      $(@_affected).find('input').attr('disabled', true)
      $(@_converse).stop().slideDown()
      $(@_converse).find('input').attr('disabled', false)



  # The *alternator* action is a more extreme toggle. It allows an element to declare its alternate:
  # when a link within the element is clicked, it will be removed from the DOM and its alternate
  # inserted. Usually the relation is reciprocal, so that another link in the alternate will bring
  # the original element back.
  #
  # The main use for this is to have two alternative blocks of form inputs: one to add a new associate
  # and one to choose from the existing list.
  #
  class Alternator
    constructor: (element) ->
      @_container = $(element)
      @_selector = @_container.attr("data-selector")
      @_alternate = @_container.siblings(@_selector)
      @revert()

    flip: (e) =>
      e.preventDefault() if e
      @_container.after(@_alternate)
      @_container.remove()
      @_alternate.find('a').click @revert

    revert: (e) =>
      e.preventDefault() if e
      @_alternate.before(@_container)
      @_alternate.remove()
      @_container.find('a').click @flip

  $.fn.alternator = ->
    @each ->
      new Alternator(@)



  $.fn.hover_table = ->
    @each ->
      $(@).find('td').hover_cell()

  $.fn.hover_cell = ->
    @each ->
      classes = @className.split(' ').join('.')
      $(@).bind "mouseenter", (e) ->
        $(".#{classes}").addClass('hover')
      $(@).bind "mouseleave", (e) ->
        $(".#{classes}").removeClass('hover')


  # The *copier* action uses Clipboard.js to put on the clipboard whatever is in our data-clipboad-text attribute
  # (or if that's missing), our textContent. More options in their docs, if you can stand them.
  #
  $.fn.copier = ->
    @each ->
      clipboard = new ClipboardJS(@)
      clipboard.on 'success', (e) ->
        $(e.trigger).signal_confirmation()
        console.log "copied", e.text


  # The main search page hasn't had much love yet.
  #
  # If we keep the inline functionality it should probably use the standard captive form.

  $.fn.search = ->
    @each ->
      new Search @

  class Search
    constructor: (element) ->
      @form = $(element)
      @search_box = @form.find(".search_box")
      @container = $(".search_results")
      @filters = @form.find "input[type='checkbox']"
      @search_box.on "keyup", @submit
      @filters.on "change", @submit

    submit: =>
      $.ajax
        url: "#{@form.attr('action')}?#{@form.serialize()}"
        type: "GET"
        dataType: "script"
        complete: (data) =>
          @container.replaceWith data.responseText
          @container = $(".search_results")


  #todo: this has been replaced with the filterform.

  $.fn.search_filter = () ->
    @each ->
      new Filter @
    @

  class Filter
    constructor: (element) ->
      @_container = $(element)
      @_defilter = $('<a href="#" class="defilter" />').insertAfter(@_container)
      @_affected = @_container.attr('data-affected')
      @setDefilter()
      @_container.bind "keyup", @setQuery
      @_defilter.bind "click", @clearQuery
      # @announce()

    setDefilter: () =>
      if @_container.val()
        @_defilter.show()
      else
        @_defilter.hide()

    setQuery: (e) =>
      kc = e.which
      #   delete,     backspace,    alphanumerics,    number pad,        punctuation
      if (kc is 8) or (kc is 46) or (47 < kc < 91) or (96 < kc < 112) or (kc > 145)
        @setDefilter()
        @filter()

    clearQuery: (e) =>
      e.preventDefault() if e
      @_container.val("")
      @setDefilter()
      @filter()

    filter: () =>
      $(@_affected).trigger "filter", @_container.val()





  # A text input that sizes to fit will adjust its font size to suit the length of its content.
  # At the moment this is done just by fitting a curve, but it ought really to be based on a
  # calculation of area occupied.

  $.size_to_fit = (e) ->
    container = $(@)
    l = container.val().length
    size = if l then (((560.0/(2 * l+150.0)) + 0.25)).toFixed(2) else 1
    container.stop().animate
      'font-size': "#{size}em"
      width: 532
      height: 290
    ,
      queue: false
      duration: 100

  $.fn.self_sizes = () ->
    @each ->
      $(@).bind "keyup", $.size_to_fit
      $(@).bind "change", $.size_to_fit
      $.size_to_fit.apply(@)
