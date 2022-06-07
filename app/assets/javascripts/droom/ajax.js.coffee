## Ajax transport
#
# This is a wrapper around the standard jquer ujs ajax machinery. it gives us a more fine-grained set of callbacks
# and a central place to do some universal work like setting pjax headers and telling elements to wait.
#
# The value of the remote: calls becomes more clear when we need to add more callbacks, eg from a widget like the
# filepicker, but perhaps they can disappear now that we've hacked up the ujs a bit.
#

#
jQuery ($) ->

  $.fn.remote = (opts) ->
    @each ->
      new Remote @, opts

  class Remote
    constructor: (element, opts) ->
      @_control = $(element)
      @_options = $.extend {}, opts
      @_control.attr('data-remote', true)
      @_control.attr('data-type', 'html')
      @_fily = false

      # catch the standard jquery_ujs events and route them to our status handlers,
      @_control.on 'ajax:beforeSend', @pend
      @_control.on 'ajax:error', @fail
      @_control.on 'ajax:success', @receive
      @_control.on 'ajax:filedata', @gotFiles
      @_control.on 'ajax:progress', @progress

      # which trigger our own more fine-grained remote:* events
      @_control.on 'remote:prepare', @_options.on_prepare
      @_control.on 'remote:progress', @_options.on_progress
      @_control.on 'remote:error', @_options.on_error
      @_control.on 'remote:success', @_options.on_success
      @_control.on 'remote:complete', @_options.on_complete
      @_control.on 'remote:cancel', @_options.on_cancel
      @activate()

    activate: () =>
      @_control.find('a.cancel').click @cancel
      @_control.trigger 'remote:prepare'

    pend: (event, xhr, settings) =>
      event.stopPropagation()
      event.preventDefault()
      xhr.setRequestHeader('X-PJAX', 'true')
      @_control.addClass('waiting')
      @_control.find('input[type=submit]').addClass('waiting')
      @_options.on_request?(xhr, settings) ? true

    gotFiles: (event, elements) =>
      @_control.trigger 'remote:upload'
      true

    progress: (e, prog) =>
      @_control.trigger "remote:progress", prog

    fail: (event, xhr, status) =>
      if xhr.status == 409
        $(event.currentTarget).children('p.error')?.text(xhr.responseText)
        $('input[type="submit"]').css("background-color", "#9b9b8e")
      if xhr.status == 401
        window.location.reload()
      event.stopPropagation()
      @_control.removeClass('waiting').addClass('erratic')
      @_control.find('input[type=submit]').removeClass('waiting')
      @_control.trigger 'remote:error', xhr, status
      @_control.trigger 'remote:complete', status

    # Note that there is no special provision here for a server side failure that results in a success response:
    # eg if validation fails and we get the form back again, this Remote will be considered successful and disappear.
    # In that case the function which triggered the remote operation is expected to do the right thing with the
    # returned html. Usually in that kind of situation you'd be using a popup, which checks for a returned form and
    # treats it as another iteration within the same window.
    #
    receive: (event, data, status, xhr) =>
      event.stopPropagation()
      @_control.removeClass('waiting')
      @_control.trigger 'remote:success', data
      @_control.trigger 'remote:complete', status

    cancel: (e) =>
      e.preventDefault() if e
      @_control.trigger 'remote:cancel'
      @_form?.remove()
