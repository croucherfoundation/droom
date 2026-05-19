(function($) {
  'use strict';

  // ========== SHARE MODAL ==========
  $(document).on('click', '[data-action="share-item"]', function(e) {
    e.preventDefault();
    var $btn = $(this);
    var type = $btn.data('shareable-type');
    var id = $btn.data('shareable-id');
    var name = $btn.data('shareable-name');

    var $modal = $('.share-modal-overlay');
    if ($modal.length) $modal.remove();

    $.get('/shares/recipients', { shareable_type: type, shareable_id: id }, function(response) {
      var existingShares = response.shares || [];
      var dataRoom = response.data_room || false;
      var modalHtml = buildShareModal(type, id, name, existingShares, dataRoom);
      $('body').append(modalHtml);
      $('.share-modal-overlay').addClass('active');
      $('.share-user-input').focus();
    });
  });

  function buildShareModal(type, id, name, existingShares, dataRoom) {
    var html = '';
    html += '<div class="standard-modal-overlay active share-modal-overlay" data-shareable-type="' + escapeHtml(type) + '" data-shareable-id="' + id + '">';
    html += '<div class="standard-modal-container active">';

    // Header — matches Croucher standard modal
    html += '<div class="standard-modal-header">';
    html += '<div class="standard-modal-close-btn cursor-pointer share-modal-close">';
    html += '<svg class="standard_close_icon"><use xlink:href="#standard_close_symbol"></use></svg>';
    html += '</div>';
    html += '<svg class="logo"><use xlink:href="#croucher_logo"></use></svg>';
    html += '<div class="container"><h2>' + escapeHtml(name) + '</h2></div>';
    html += '</div>';

    // Body
    html += '<div class="standard-modal-body" style="overflow:visible;"><div class="container" style="overflow:visible;"><div class="inputs" style="overflow:visible;">';

    // Invite people section
    html += '<p><strong>Invite people</strong></p>';
    html += '<div class="share-user-search" style="position:relative;overflow:visible;">';
    html += '<div style="display:flex;align-items:center;gap:8px;">';
    html += '<div class="share-input-box" style="flex:1;position:relative;display:flex;flex-wrap:wrap;align-items:center;gap:4px;padding:6px 0;border-bottom:1px solid #ccc;min-height:38px;cursor:text;">';
    html += '<div class="share-selected-users" style="display:contents;"></div>';
    html += '<input class="share-user-input" type="text" placeholder="Add a name or email..." autocomplete="off" style="flex:1;min-width:120px;padding:4px 0;border:none;outline:none;font-size:16px;">';
    html += '</div>';
    html += '<a class="croucher-standard-btn share-invite-btn" style="display:none;white-space:nowrap;">Invite</a>';
    html += '</div>';
    html += '<ul class="share-user-suggestions" style="position:absolute;left:0;top:100%;z-index:9999;background:#fff;border:1px solid #ddd;border-radius:4px;width:100%;max-height:200px;overflow-y:auto;list-style:none;padding:0;margin:4px 0 0;display:none;box-shadow:0 4px 12px rgba(0,0,0,0.15);"></ul>';
    html += '</div>';

    // Existing shares (invited people list)
    html += '<ul class="share-existing-list" style="list-style:none;padding:0;margin:12px 0 0;max-height:200px;overflow-y:auto;">';
    if (existingShares.length > 0) {
      for (var i = 0; i < existingShares.length; i++) {
        html += shareRecipientRow(existingShares[i]);
      }
    }
    html += '</ul>';

    // Share with data room section
    html += '<div style="margin-top:24px;"><strong>Share with data room</strong></div>';
    html += '<div style="margin-top:8px;"><select class="share-data-room-access" style="width:100%;padding:8px;font-size:14px;">';
    html += '<option value="none"' + (!dataRoom ? ' selected' : '') + '>Not shared with data room</option>';
    html += '<option value="shared"' + (dataRoom ? ' selected' : '') + '>Shared</option>';
    html += '</select></div>';
    html += '<div class="share-data-room-hint" style="margin-top:4px;font-size:13px;color:#666;">';
    html += dataRoom ? 'Everyone in the data room can open and read this.' : 'Only you and invited people can access this.';
    html += '</div>';
    html += '</div></div></div>';

    // Footer — matches Croucher standard modal
    html += '<div class="standard-modal-footer"><div class="buttons">';
    html += '<a class="cancel submit-button share-modal-close">Cancel</a>';
    html += '<a class="croucher-standard-btn share-submit-btn">Done</a>';
    html += '</div></div>';

    html += '</div></div>';
    return html;
  }

  function shareRecipientRow(share) {
    var avatarHtml;
    if (share.avatar_url) {
      avatarHtml = '<img src="' + escapeHtml(share.avatar_url) + '" style="width:32px;height:32px;border-radius:50%;object-fit:cover;flex-shrink:0;">';
    } else {
      var initials = (share.name || '').split(' ').map(function(n){ return n.charAt(0).toUpperCase(); }).join('').substring(0,2);
      avatarHtml = '<span style="width:32px;height:32px;border-radius:50%;background:#8ecae6;display:inline-flex;align-items:center;justify-content:center;font-size:12px;font-weight:600;color:#fff;flex-shrink:0;">' + initials + '</span>';
    }
    var html = '<li data-share-id="' + share.id + '" data-user-id="' + share.user_id + '" style="display:flex;align-items:center;padding:8px 0;gap:12px;">';
    html += avatarHtml;
    html += '<span style="flex:1;"><strong>' + escapeHtml(share.name) + '</strong><br><small>' + escapeHtml(share.email || '') + '</small></span>';
    html += '<a class="share-remove-btn" data-share-id="' + share.id + '" style="cursor:pointer;font-size:18px;color:#999;text-decoration:none;" title="Remove">&times;</a>';
    html += '</li>';
    return html;
  }

  // Close modal
  $(document).on('click', '.share-modal-close', function(e) {
    e.preventDefault();
    $('.share-modal-overlay').remove();
  });

  // Update hint when data room dropdown changes
  $(document).on('change input', 'select.share-data-room-access', function() {
    var hint = $(this).val() === 'shared'
      ? 'Everyone in the data room can open and read this.'
      : 'Only you and invited people can access this.';
    $(this).closest('.inputs').find('.share-data-room-hint').text(hint);
  });

  // Focus input when clicking the input box
  $(document).on('click', '.share-input-box', function() {
    $(this).find('.share-user-input').focus();
  });

  // Close on overlay click
  $(document).on('click', '.share-modal-overlay', function(e) {
    if ($(e.target).hasClass('share-modal-overlay')) {
      $('.share-modal-overlay').remove();
    }
  });

  // Copy link
  $(document).on('click', '.share-copy-link-btn', function(e) {
    e.preventDefault();
    var $modal = $('.share-modal-overlay');
    var type = $modal.data('shareable-type');
    var id = $modal.data('shareable-id');
    var url = window.location.origin + '/folders/' + id;
    if (type === 'Droom::Document') {
      // For documents, use folder/document path
      url = window.location.href;
    }
    if (navigator.clipboard) {
      navigator.clipboard.writeText(url);
      $(this).text('Copied!');
      var $btn = $(this);
      setTimeout(function() { $btn.text('Copy link'); }, 2000);
    }
  });

  // User search autocomplete
  var searchTimeout;
  $(document).on('input', '.share-user-input', function() {
    var $input = $(this);
    var query = $input.val().trim();
    var $suggestions = $input.closest('.share-user-search').find('.share-user-suggestions');

    clearTimeout(searchTimeout);
    if (query.length < 2) {
      $suggestions.empty().hide();
      return;
    }

    searchTimeout = setTimeout(function() {
      $.get('/users/suggest', { name: query }, function(users) {
        $suggestions.empty();
        var existingIds = getExistingShareUserIds();
        var selectedIds = getSelectedChipUserIds();
        if (users && users.length) {
          for (var i = 0; i < users.length; i++) {
            if (existingIds.indexOf(users[i].uid) === -1) {
              var isChecked = selectedIds.indexOf(users[i].uid) !== -1;
              $suggestions.append(
                '<li data-user-id="' + users[i].uid + '" data-user-name="' + escapeHtml(users[i].name) + '" data-user-email="' + escapeHtml(users[i].email || '') + '" style="padding:8px 12px;cursor:pointer;display:flex;align-items:center;gap:8px;">' +
                '<input type="checkbox" class="share-suggest-checkbox" ' + (isChecked ? 'checked' : '') + ' style="pointer-events:none;">' +
                '<span>' + escapeHtml(users[i].name) + ' <small style="color:#666;">(' + escapeHtml(users[i].email || '') + ')</small></span></li>'
              );
            }
          }
        }
        if ($suggestions.children().length > 0) {
          $suggestions.css('display', 'block');
        } else {
          $suggestions.css('display', 'none');
        }
      });
    }, 300);
  });

  // Hover effect on suggestions
  $(document).on('mouseenter', '.share-user-suggestions li', function() {
    $(this).css('background', '#f5f5f5');
  });
  $(document).on('mouseleave', '.share-user-suggestions li', function() {
    $(this).css('background', '');
  });

  // Select a user from suggestions — toggle in pending list
  $(document).on('mousedown', '.share-user-suggestions li', function(e) {
    e.preventDefault(); // prevent input blur
    var $li = $(this);
    var userId = $li.data('user-id');
    var userName = $li.data('user-name');

    var $modal = $('.share-modal-overlay');
    var $selected = $modal.find('.share-selected-users');
    var $existing = $selected.find('[data-user-id="' + userId + '"]');

    if ($existing.length) {
      // Uncheck — remove chip
      $existing.remove();
      $li.find('.share-suggest-checkbox').prop('checked', false);
    } else {
      // Check — add chip
      $selected.append(
        '<span class="share-user-chip" data-user-id="' + userId + '" style="display:inline-flex;align-items:center;gap:4px;padding:2px 8px;background:#e8f4fd;border-radius:12px;font-size:12px;line-height:1.6;">' +
        escapeHtml(userName) +
        '<a class="share-chip-remove" style="cursor:pointer;font-weight:bold;color:#999;margin-left:2px;">&times;</a>' +
        '</span>'
      );
      $li.find('.share-suggest-checkbox').prop('checked', true);
    }

    // Clear search and hide suggestions
    $modal.find('.share-user-input').val('');
    $modal.find('.share-user-suggestions').empty().css('display', 'none');

    // Show/hide invite button
    if ($selected.find('.share-user-chip').length > 0) {
      $modal.find('.share-invite-btn').show();
    } else {
      $modal.find('.share-invite-btn').hide();
    }
  });

  // Remove a chip
  $(document).on('click', '.share-chip-remove', function(e) {
    e.preventDefault();
    $(this).closest('.share-user-chip').remove();
    var $modal = $('.share-modal-overlay');
    if ($modal.find('.share-selected-users .share-user-chip').length === 0) {
      $modal.find('.share-invite-btn').hide();
    }
  });

  // Invite button — create shares for all selected users
  $(document).on('click', '.share-invite-btn', function(e) {
    e.preventDefault();
    var $modal = $('.share-modal-overlay');
    var type = $modal.data('shareable-type');
    var id = $modal.data('shareable-id');
    var userIds = [];

    $modal.find('.share-selected-users .share-user-chip').each(function() {
      userIds.push($(this).data('user-id'));
    });

    if (userIds.length === 0) return;

    $.ajax({
      url: '/shares',
      method: 'POST',
      data: { shareable_type: type, shareable_id: id, user_ids: userIds },
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      success: function(data) {
        var $list = $modal.find('.share-existing-list');
        $list.find('.no-shares').remove();
        $list.empty();
        for (var i = 0; i < data.shares.length; i++) {
          $list.append(shareRecipientRow(data.shares[i]));
        }
        $modal.find('.share-selected-users').empty();
        $modal.find('.share-invite-btn').hide();
      }
    });
  });

  // Remove an existing share
  $(document).on('click', '.share-remove-btn', function(e) {
    e.preventDefault();
    var $btn = $(this);
    var shareId = $btn.data('share-id');

    $.ajax({
      url: '/shares/' + shareId,
      method: 'DELETE',
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      success: function() {
        $btn.closest('li').remove();
      }
    });
  });

  // Done button — save data room setting and close modal
  $(document).on('click', '.share-submit-btn', function(e) {
    e.preventDefault();
    var $modal = $('.share-modal-overlay');
    var type = $modal.data('shareable-type');
    var id = $modal.data('shareable-id');
    var dataRoomVal = $modal.find('.share-data-room-access').val();
    var dataRoom = (dataRoomVal === 'shared');

    // Determine endpoint
    var url, paramKey;
    if (type === 'Droom::Folder') {
      url = '/folders/' + id;
      paramKey = 'folder';
    } else {
      url = '/documents/' + id;
      paramKey = 'document';
    }

    var data = {};
    data[paramKey] = { data_room: dataRoom };

    $.ajax({
      url: url,
      method: 'PATCH',
      data: data,
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      success: function() {
        $modal.remove();
        showFavouriteAlert('Sharing updated.');
      },
      error: function() {
        $modal.remove();
      }
    });
  });

  function getExistingShareUserIds() {
    var ids = [];
    $('.share-existing-list li[data-user-id]').each(function() {
      ids.push(parseInt($(this).data('user-id')));
    });
    return ids;
  }

  function getSelectedChipUserIds() {
    var ids = [];
    $('.share-selected-users .share-user-chip').each(function() {
      ids.push(parseInt($(this).data('user-id')));
    });
    return ids;
  }

  // ========== FAVOURITE TOGGLE ==========
  $(document).on('click', '[data-action="toggle-favourite"]', function(e) {
    e.preventDefault();
    var $btn = $(this);
    var type = $btn.data('favouritable-type');
    var id = $btn.data('favouritable-id');
    var favouriteId = $btn.data('favourite-id');
    var isFavourited = $btn.data('favourited');

    if (isFavourited) {
      $.ajax({
        url: '/favourites/' + favouriteId,
        method: 'DELETE',
        headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
        success: function() {
          $btn.data('favourited', false).data('favourite-id', '');
          $btn.find('svg use').attr('href', '#star_outline_symbol').attr('xlink:href', '#star_outline_symbol');
          $btn.css('color', '');
          $btn.attr('title', 'Add to favourites');
          showFavouriteAlert('Removed from favourites');
        }
      });
    } else {
      $.ajax({
        url: '/favourites',
        method: 'POST',
        data: { favouritable_type: type, favouritable_id: id },
        headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
        success: function(data) {
          $btn.data('favourited', true).data('favourite-id', data.id);
          $btn.find('svg use').attr('href', '#star_filled_symbol').attr('xlink:href', '#star_filled_symbol');
          $btn.css('color', '#f5a623');
          $btn.attr('title', 'Remove from favourites');
          showFavouriteAlert('Added to favourites');
        }
      });
    }
  });

  function showFavouriteAlert(message) {
    var $alert = $('<div class="favourite-alert" style="position:fixed;top:20px;right:50px;background:rgba(116,184,122,0.9);color:#fff;padding:16px;border-radius:3px;font-size:14px;z-index:99999;opacity:0;transition:opacity 0.3s;box-shadow:0 2px 8px rgba(0,0,0,0.15);border:1px solid #74b87a;">' + message + '</div>');
    $('body').append($alert);
    setTimeout(function() { $alert.css('opacity', '1'); }, 10);
    setTimeout(function() {
      $alert.css('opacity', '0');
      setTimeout(function() { $alert.remove(); }, 300);
    }, 2000);
  }

  function escapeHtml(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
  }

})(jQuery);
