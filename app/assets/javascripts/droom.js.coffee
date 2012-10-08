#= require droom/lib/modernizr
#= require droom/lib/extensions
#= require jquery
#= require jquery_ujs
#= require droom/lib/jquery.animate-colors
#= require droom/lib/kalendae
#= require droom/lib/wysihtml5
#= require droom/lib/parser_rules/advanced
#= require droom/forms
#= require droom/suggester
#= require droom/calendar
#= require droom/sort
#= require droom/map
#= require_self

jQuery ($) ->
  $.fn.flash = ->
    @each ->
      container = $(this)
      container.fadeIn "fast"
      $("<a href=\"#\" class=\"closer\">close</a>").prependTo(container)
      container.bind "click", (e) ->
        e.preventDefault()
        container.fadeOut "fast"

  $.fn.signal = (color, duration) ->
    color ?= "#f7f283"
    duration ?= 1000
    @each ->
      $(@).css('backgroundColor', color).animate({'backgroundColor': '#ffffff'}, duration)
      
  $.fn.signal_confirmation = ->
    @signal('#c7ebb4')

  $.fn.signal_error = ->
    @signal('#e55a51')

  $.fn.signal_cancellation = ->
    @signal('#a2a3a3')

  $.fn.find_including_self = (selector) ->
    selection = @.find(selector)
    selection.push @ if @is(selector)
    selection

  $.fn.activate = () ->
    @find_including_self('#flashes p:parent').flash()
    @find_including_self('.twister').twister()
    @find_including_self('.wysihtml').html_editable()
    @find_including_self('.venuepicker').venue_picker()
    @find_including_self('.datepicker').date_picker()
    @find_including_self('.timepicker').time_picker()
    @find_including_self('.filepicker').file_picker()
    @find_including_self('a.delete').removes('.holder')
    @find_including_self('[data-action="popup"]').popup_remote_content()
    @find_including_self('[data-action="toggle"]').toggle()
    @find_including_self('[data-action="append_form"]').append_remote_form()
    @find_including_self('[data-action="overlay_form"]').overlay_remote_form()
    @find_including_self('[data-action="replace_with_form"]').replace_with_remote_form()
    @find_including_self('[data-refreshable]').refresher()
    @find_including_self('table.sortable').table_sort
      sort: "created"
      order: "DESC"
    @find_including_self('#map').init_map()
    @find_including_self('input.password').password_field()
    @
      
$ ->
  $('body').activate()
  $('#minicalendar').calendar()
  $('form#searchform').captive
    replacing: '.search_results'
    fast: true
