// User search filter for library views.
// Renders a dropdown matching the select_tag pattern with a search input inside.
(function($) {
  $.fn.userFilter = function() {
    return this.each(function() {
      var $el = $(this);
      if ($el.data('user-filter-init')) return;
      $el.data('user-filter-init', true);

      var $form = $el.closest('form');
      var $hidden = $form.find('input[name="user_id"]');
      var selectedName = $el.data('selected-name') || '';
      var placeholder = $el.data('placeholder') || 'Uploaded by';
      var request = null;
      var cache = {};
      var isOpen = false;

      // Build dropdown markup matching the select.custom_dropdown.custom-img pattern
      var $wrapper = $('<div class="user-filter-dropdown"></div>');
      var $button = $('<button type="button" class="user-filter-btn"></button>');
      var $label = $('<span class="user-filter-label"></span>');
      var $clear = $('<span class="user-filter-clear">&times;</span>').hide();
      var $panel = $('<div class="user-filter-panel"></div>').hide();
      var $search = $('<input type="text" class="user-filter-search" placeholder="Search by name or email" autocomplete="off" data-slow="true">');
      var $list = $('<ul class="user-filter-list"></ul>');

      $button.append($label).append($clear);
      $panel.append($search).append($list);
      $wrapper.append($button).append($panel);
      $el.replaceWith($wrapper);

      // Set initial state
      if (selectedName) {
        $label.text(selectedName);
        $label.removeClass('placeholder');
        $clear.show();
      } else {
        $label.text(placeholder);
        $label.addClass('placeholder');
      }

      function open() {
        if (isOpen) return;
        isOpen = true;
        $panel.stop().slideDown(150);
        $wrapper.addClass('open');
        $search.val('').focus();
        $list.empty();
      }

      function close() {
        if (!isOpen) return;
        isOpen = false;
        $panel.stop().slideUp(150);
        $wrapper.removeClass('open');
      }

      function selectUser(id, name) {
        $label.text(name).removeClass('placeholder');
        $hidden.val(id).trigger('change');
        $clear.show();
        close();
      }

      function clearSelection(e) {
        e.stopPropagation();
        $label.text(placeholder).addClass('placeholder');
        $hidden.val('').trigger('change');
        $clear.hide();
      }

      function populate(items) {
        $list.empty();
        if (items.length === 0) {
          $list.append('<li class="no-results">No users found</li>');
          return;
        }
        $.each(items, function(i, item) {
          var $li = $('<li></li>');
          var $avatar = $('<img class="user-filter-avatar">').attr('src', item.avatar_url || '');
          var $info = $('<div class="user-filter-info"></div>');
          $info.append($('<span class="user-filter-name"></span>').text(item.value));
          if (item.email) {
            $info.append($('<span class="user-filter-email"></span>').text(item.email));
          }
          $li.append($avatar).append($info);
          $li.on('mousedown', function(e) {
            e.preventDefault();
            selectUser(item.id, item.value);
          });
          $list.append($li);
        });
      }

      // Toggle on button click
      $button.on('click', function(e) {
        e.preventDefault();
        if (isOpen) { close(); } else { open(); }
      });

      // Close on click outside
      $(document).on('mousedown', function(e) {
        if (!$wrapper[0].contains(e.target)) close();
      });

      // Stop change from bubbling to CaptiveForm
      $search.on('change', function(e) { e.stopPropagation(); });

      // Search as user types, stop keyup from bubbling to CaptiveForm
      $search.on('keyup', function(e) {
        e.stopPropagation();
        if ([13, 27, 38, 40].indexOf(e.which) !== -1) return;
        var q = $search.val().trim();
        if (q.length < 2) { $list.empty(); return; }
        if (cache[q]) { populate(cache[q]); return; }
        if (request) request.abort();
        request = $.getJSON('/users/search.json', { q: q }, function(users) {
          var items = $.map(users, function(u) {
            var display = u.email ? u.name + ' (' + u.email + ')' : u.name;
            return { id: u.id, value: u.name, email: u.email, avatar_url: u.avatar_url };
          });
          cache[q] = items;
          populate(items);
        });
      });

      // Prevent search input clicks from closing
      $search.on('mousedown', function(e) { e.stopPropagation(); });

      // Clear button
      $clear.on('click', clearSelection);
    });
  };
})(jQuery);