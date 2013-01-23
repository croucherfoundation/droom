jQuery ($) ->
  class Search
    constructor: (element) ->
      @search_box = $(element)
      @container = $(".search_results")
      @search_box.on "keyup", @submit

    submit: =>
      $.ajax
        url: "search?term=#{@search_box.val()}"
        type: "GET"
        dataType: "script"
        complete: (data) =>
          console.log data.responseText
          @container.replaceWith data.responseText
          @container = $(".search_results")

  $.fn.search = ->
    @each ->
      new Search @
      
  $.namespace "Droom", (target, top) ->
    target.Search = Search
