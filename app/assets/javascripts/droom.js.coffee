#= require jquery
#= require droom/lib/jquery_ujs
#= require droom/lib/assets

#= require underscore/underscore
#= require clipboard/dist/clipboard
#= require jquery-deserialize/src/jquery.deserialize
#= require sortablejs/Sortable
#= require jquery.cookie/jquery.cookie
#= require ep-jquery-tokeninput/src/jquery.tokeninput
#= require imagesloaded/imagesloaded.pkgd

#= require droom/lib/jquery.datepicker
#= require droom/lib/jquery.animate-colors

#= require droom/extensions
#= require droom/utilities
#= require droom/ajax

#= require droom/actions
#= require droom/popups
#= require droom/stream
#= require droom/tagger
#= require droom/uploader
#= require droom/draggables
#= require droom/widgets
#= require droom/editors
#= require droom/grid
#= require_self


jQuery ($) ->
  console.log "loading droom"

  # set flags that scripts can observe cheaply.
  #
  if window.matchMedia('(max-width: 700px)').matches
    $('body').addClass('mobile')
    if window.matchMedia('(orientation: portrait)').matches
      $('body').addClass('portrait')
    else
      $('body').addClass('landscape')

  if 'ontouchstart' in window
    $('body').addClass('touch')
  else
    $('body').addClass('no-touch')

  $.activate_with () ->
    @find_including_self('form.droom_faceter').faceting_search()
    @find_including_self('#flashes p:parent').flash()
    @find_including_self('[data-refreshing]').refresher()
    @find_including_self('.hidden').find('input, select, textarea').attr('disabled', true)
    @find_including_self('.temporary').disappearAfter(1000)
    @find_including_self('.subordinate').subordinate()
    @find_including_self('.insubordinate').insubordinate()

    # link actions

    @find_including_self('[data-action="popup"]').popup()
    @find_including_self('[data-action="close"]').closes()
    @find_including_self('[data-action="affect"]').affects()
    @find_including_self('[data-action="reveal"]').reveals()
    @find_including_self('[data-action="remove"]').removes()
    @find_including_self('[data-action="remove_all"]').removes_all()
    @find_including_self('[data-action="copy"]').copier()
    @find_including_self('[data-action="setter"]').setter()
    @find_including_self('[data-action="toggle"]').toggle()
    @find_including_self('[data-action="alternate"]').alternator()
    @find_including_self('[data-action="replace"]').replace_with_remote_content()
    @find_including_self('[data-action="update_content"]').update_main_content()
    @find_including_self('[data-action="autofetch"]').replace_with_remote_content ".holder", {force: true}
    @find_including_self('[data-action="slide"]').sliding_link()
    @find_including_self('[data-action="proxy"]').click_proxy()
    @find_including_self('[data-action="fit"]').self_sizes()
    @find_including_self('form[data-action="filter"]').filter_form()
    @find_including_self('form[data-action="quick_search"]').quick_search_form()
    @find_including_self('form[data-action="table_filter"]').table_filter_form()
    @find_including_self('div[data-panel]').panel()
    @find_including_self('[data-menu]').action_menu()
    @find_including_self('table[data-hoverable]').hover_table()
    @find_including_self('[data-action="append_fields"]').appends_fields()
    @find_including_self('[data-action="remove_fields"]').removes_fields()
    @find_including_self('[data-action="reinvite"]').reinviter()

    # it's not very easy to add data attributes to kaminari pagination links

    @find_including_self('.pagination.sliding a').page_turner()

    # and some shortcuts for compatibility

    @find_including_self('a.inline, a.fetch').replace_with_remote_content()

    # form widgets and input modification. These are moving to [data-role] markup.

    @find_including_self('textarea.rte').html_editable()
    @find_including_self('[data-role="datepicker"]').date_picker()
    @find_including_self('.timepicker').time_picker()
    @find_including_self('.person_selector').person_selector()
    @find_including_self('.person_picker').person_picker()
    @find_including_self('.group_picker').group_picker()
    @find_including_self('fieldset[data-role="password"]').password_fieldset()
    @find_including_self('input[type="submit"]').submitter()
    @find_including_self('form.scrap').scrap_form()
    @find_including_self('[data-role="filepicker"]').file_picker()
    @find_including_self('[data-role="imagepicker"]').droom_image_picker()
    @find_including_self('[data-role="venuepicker"]').venue_picker()
    @find_including_self('[data-role="slug"]').slug_field()
    @find_including_self('[data-droppable]').droploader()
    @find_including_self('[data-sortable]').sortable_list()

    # page widgets

    @find_including_self('#minicalendar').calendar()
    @find_including_self('form.search_form').search()
    @find_including_self('form.fancy').captive()
    @find_including_self('li.folder').folder()
    @find_including_self('form#suggestions').suggestion_form()
    @find_including_self('.sortable_files').sortable_files()
    @find_including_self('[data-draggable]').draggable()
    @find_including_self('.gridbox:not(.notice)').gridBox()
    @find_including_self('.tagger').tagger()
    @find_including_self('form.search.quick').quick_search_form()

    @find_including_self('#noticeboard').imagesLoaded =>
      console.log "imagesLoaded ", @
      $('.notice').notice()

    @
