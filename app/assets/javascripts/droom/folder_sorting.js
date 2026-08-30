(function() {
  'use strict';

  $.fn.sortable_folders = function() {
    return this.each(function() {
      return new SortableFolders(this);
    });
  };

  var SortableFolders = (function() {
    function SortableFolders(element) {
      this.setPosition = this.setPosition.bind(this);
      this._container = $(element);
      
      console.log('Initializing SortableFolders on', element.id || element.className);
      
      // Initialize Sortable - only sort direct li.folder children
      this._sortable = new Sortable(element, {
        handle: '.drag-handle',
        draggable: '> li.folder',  // Only direct children with .folder class
        sort: true,
        animation: 150,
        ghostClass: 'folder-ghost',
        chosenClass: 'folder-chosen',
        dragClass: 'folder-drag',
        direction: 'vertical',
        swapThreshold: 0.65,
        invertSwap: false,
        onUpdate: this.setPosition
      });
      
      // Recursively initialize nested folder lists
      // Nested folders are in: li.folder > ul.filing > li.folders > ul
      this._container.find('> li.folder > ul > li.folders > ul').each(function() {
        console.log('Initializing nested folder list');
        $(this).sortable_folders();
      });
    }

    SortableFolders.prototype.setPosition = function(e) {
      var $el = $(e.item);
      var folderId = $el.attr('id').replace('folder_', '');
      var newPosition = e.newIndex + 1;
      
      console.log('Reordering folder', folderId, 'to position', newPosition);
      
      $.ajax({
        method: 'PUT',
        url: '/folders/' + folderId + '/reposition',
        data: {
          position: newPosition
        },
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        success: function() {
          console.log('Folder reordered successfully');
          $el.signal_confirmation();
        },
        error: function(xhr, status, error) {
          console.error('Failed to reorder folder:', error, xhr.responseText);
        }
      });
    };

    return SortableFolders;
  })();

}).call(this);
