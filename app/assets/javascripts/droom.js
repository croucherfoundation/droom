//= require jquery
//= require droom/lib/jquery_ujs
//= require droom/lib/assets

//= require underscore/underscore
//= require clipboard/dist/clipboard
//= require jquery-deserialize/src/jquery.deserialize
//= require sortablejs/Sortable
//= require jquery.cookie/jquery.cookie
//= require ep-jquery-tokeninput/src/jquery.tokeninput
//= require imagesloaded/imagesloaded.pkgd

//= require droom/lib/jquery.datepicker
//= require droom/lib/jquery.animate-colors

//= require droom/extensions
//= require droom/utilities
//= require droom/ajax

//= require droom/actions
//= require droom/popups
//= require droom/stream
//= require droom/tagger
//= require droom/uploader
//= require droom/draggables
//= require droom/widgets
//= require droom/editors
//= require droom/grid
//= require_self


(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  jQuery(function($) {
    console.log("loading droom");
    if (window.matchMedia('(max-width: 991px)').matches) {
      $('body').addClass('mobile');
      if (window.matchMedia('(orientation: portrait)').matches) {
        $('body').addClass('portrait');
      } else {
        $('body').addClass('landscape');
      }
    }
    if (indexOf.call(window, 'ontouchstart') >= 0) {
      $('body').addClass('touch');
    } else {
      $('body').addClass('no-touch');
    }
    return $.activate_with(function() {
      this.find_including_self('form.droom_faceter').faceting_search();
      this.find_including_self('#flashes p:parent').flash();
      this.find_including_self('[data-refreshing]').refresher();
      this.find_including_self('.hidden').find('input, select, textarea').attr('disabled', true);
      this.find_including_self('.temporary').disappearAfter(1000);
      this.find_including_self('.subordinate').subordinate();
      this.find_including_self('.insubordinate').insubordinate();
      this.find_including_self('[data-action="popup"]').popup();
      this.find_including_self('[data-action="close"]').closes();
      this.find_including_self('[data-action="affect"]').affects();
      this.find_including_self('[data-action="reveal"]').reveals();
      this.find_including_self('[data-action="remove"]').removes();
      this.find_including_self('[data-action="remove_all"]').removes_all();
      this.find_including_self('[data-action="copy"]').copier();
      this.find_including_self('[data-action="setter"]').setter();
      this.find_including_self('[data-action="toggle"]').toggle();
      this.find_including_self('[data-action="alternate"]').alternator();
      this.find_including_self('[data-action="replace"]').replace_with_remote_content();
      this.find_including_self('[data-action="update_content"]').update_main_content();
      this.find_including_self('[data-action="autofetch"]').replace_with_remote_content(".holder", {
        force: true
      });
      this.find_including_self('[data-action="slide"]').sliding_link();
      this.find_including_self('[data-action="proxy"]').click_proxy();
      this.find_including_self('[data-action="fit"]').self_sizes();
      this.find_including_self('form[data-action="filter"]').filter_form();
      this.find_including_self('form[data-action="quick_search"]').quick_search_form();
      this.find_including_self('form[data-action="table_filter"]').table_filter_form();
      this.find_including_self('div[data-panel]').panel();
      this.find_including_self('[data-menu]').action_menu();
      this.find_including_self('table[data-hoverable]').hover_table();
      this.find_including_self('[data-action="append_fields"]').appends_fields();
      this.find_including_self('[data-action="remove_fields"]').removes_fields();
      this.find_including_self('[data-action="reinvite"]').reinviter();
      this.find_including_self('.pagination.sliding a').page_turner();
      this.find_including_self('a.inline, a.fetch').replace_with_remote_content();
      this.find_including_self('textarea.rte').html_editable();
      this.find_including_self('[data-role="datepicker"]').date_picker();
      this.find_including_self('.timepicker').time_picker();
      this.find_including_self('.person_selector').person_selector();
      this.find_including_self('.person_picker').person_picker();
      this.find_including_self('.group_picker').group_picker();
      this.find_including_self('fieldset[data-role="password"]').password_fieldset();
      this.find_including_self('input[type="submit"]').submitter();
      this.find_including_self('form.scrap').scrap_form();
      this.find_including_self('[data-role="filepicker"]').file_picker();
      this.find_including_self('[data-role="imagepicker"]').droom_image_picker();
      this.find_including_self('[data-role="venuepicker"]').venue_picker();
      this.find_including_self('[data-role="slug"]').slug_field();
      this.find_including_self('[data-droppable]').droploader();
      this.find_including_self('[data-sortable]').sortable_list();
      this.find_including_self('#minicalendar').calendar();
      this.find_including_self('form.search_form').search();
      this.find_including_self('form.fancy').captive();
      this.find_including_self('li.folder').folder();
      this.find_including_self('form#suggestions').suggestion_form();
      if (!$('body').hasClass('mobile')) {
        this.find_including_self('.sortable_files').sortable_files();
      }
      this.find_including_self('[data-draggable]').draggable();
      this.find_including_self('.gridbox:not(.notice)').gridBox();
      this.find_including_self('.tagger').tagger();
      this.find_including_self('form.search.quick').quick_search_form();
      this.find_including_self('#noticeboard').imagesLoaded((function(_this) {
        return function() {
          console.log("imagesLoaded ", _this);
          return $('.notice').notice();
        };
      })(this));
      return this;
    });
  });

}).call(this);