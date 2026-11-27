// A Library uploader must be present in the current view and folder search.
(function ($) {
  $.fn.userFilter = function () {
    return this.each(function () {
      var host = $(this);
      if (host.data('user-filter-init')) return;
      host.data('user-filter-init', true);
      var form = host.closest('form');
      var wrapper = $('<div class="user-filter-dropdown"></div>');
      var button = $('<button type="button" class="user-filter-btn" aria-expanded="false">People</button>');
      var panel = $('<div class="user-filter-panel"></div>').hide();
      var input = $('<input type="search" class="user-filter-search" aria-label="Search people" placeholder="Search by name or email" autocomplete="off">');
      var list = $('<ul class="user-filter-list"></ul>');
      var request;
      var timer;
      panel.append(input, list);
      host.replaceWith(wrapper.append(button, panel));

      function cancel() {
        clearTimeout(timer);
        if (request) request.abort();
      }

      function close() {
        cancel();
        panel.hide();
        button.attr('aria-expanded', 'false');
      }

      function populate(users) {
        list.empty();
        if (!users.length) list.append($('<li></li>').text('No users found'));
        users.forEach(function (user) {
          var choice = $('<button type="button"></button>').text(user.name);
          choice.on('click', function () {
            form.find('input[name="user_id"]').val(user.id).trigger('change');
            close();
            button.trigger('focus');
          });
          list.append($('<li></li>').append(choice));
        });
      }

      button.on('click', function () {
        if (panel.is(':visible')) return close();
        list.empty();
        panel.show();
        button.attr('aria-expanded', 'true');
        input.val('').trigger('focus');
      });

      wrapper.on('focusout', function (event) {
        if (!wrapper[0].contains(event.relatedTarget)) close();
      });

      // Keep typing in the People field local to the picker.
      input.on('keydown keyup change', function (event) {
        event.stopPropagation();
        if (event.key === 'Enter') event.preventDefault();
        if (event.key === 'Escape') {
          close();
          button.trigger('focus');
        }
      });

      input.on('input', function () {
        cancel();
        list.empty();
        var term = input.val().trim();
        if (term.length < 2) return;
        timer = setTimeout(function () {
          var params = form.serializeArray();
          params.push({name: 'people_query', value: term});
          request = $.getJSON(form.attr('action').replace(/\/$/, '') + '.json', params, populate);
        }, 160);
      });
    });
  };
})(jQuery);
