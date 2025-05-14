$.fn.file_selector = function () {
  return this.each(function () {
    return new FileSelector(this);
  });
};

class FileSelector {
  constructor(containerSelector) {
    this.$container = $(containerSelector);
    this.$items = this.$container.children('li');
    this.lastSelectedIndex = null;

    this.initEvents();
    this.initSortable();
  }

  initEvents() {
    this.$container.on('click', 'li', (e) => this.handleClick(e));

    $(document).on('keydown', (e) => {
      if (e.key === 'Delete' || e.key === 'Backspace') {
        this.deleteSelected();
      }
    });
  }

  initSortable() {
    const isWindows = /Windows/.test(navigator.userAgent);

    new Sortable(this.$container[0], {
      multiDrag: true,                
      selectedClass: 'selected',
      animation: 150,
      fallbackTolerance: 3,
      multiDragKey: isWindows ? 'ctrl' : 'meta',
      onStart: (evt) => this.handleSortingStart(evt),
      onEnd: (evt) => this.handleSortingEnd(evt)
    });
  }

  handleClick(event) {
    const $clickedItem = $(event.currentTarget);
    const index = this.$items.index($clickedItem);

    if (event.shiftKey && this.lastSelectedIndex !== null) {
      const [start, end] = [this.lastSelectedIndex, index].sort(
        (a, b) => a - b
      );
      this.$items.slice(start, end + 1).addClass('selected');
    } else {
      this.$items.removeClass('active');
      this.lastSelectedIndex = index;
    }
  }

  deleteSelected() {
    const $this = this;
    const selected = $this.$items.filter('.selected');

    if (selected.length === 0) {
    $this.showAlert('error', 'Select files to delete!');
      return;
    }

    const eventId = $this.$container.data('eventId');
    const imageIds = selected.map((_, item) => $(item).data('imageId')).get();
    console.log('imageids', imageIds);
    const pageNumbers = selected
      .map((_, item) => $(item).data('pageNumber'))
      .get();

    const url = '/thumbnails/batch_destroy';

    $this.showAlert('notice', 'Deleting files...');
    $('body').addClass('overlay-active');

    $.ajax({
      url: url,
      type: 'DELETE',
      data: { event_id: eventId, image_ids: imageIds },
      success: function () {
        selected.remove();
        $this.removePages(pageNumbers);
        $this.$items = $this.$container.children('li');
        $this.lastSelectedIndex = null;
        $this.showAlert('notice', 'Files deleted successfully.');
        $('body').removeClass('overlay-active');
      },
      error: function (xhr, status, error) {
        $('body').removeClass('overlay-active');
        $this.showAlert('error', 'Failed to delete files!');
        console.error('Delete failed:', status, error);
      },
    });
  }

  handleSortingStart(evt) {
    const selectedItems = this.$items.filter('.selected');
    selectedItems.each(function () {
      const itemIndex = $(this).index();
      $(this).data('original-index', itemIndex);
    });
  }
 
  handleSortingEnd(evt) {
    // Refresh cached items
    this.$items = this.$container.children('li');
    const newOrder = [];
 
    this.$items.each((index, item) => {
      newOrder.push($(item).data('imageId'));
    });
    console.log('New order after sorting:', newOrder);
    // You can POST this order to the server if needed
  }

  removePages(pageNumbers) {
    pageNumbers.forEach((pageNumber) => {
      $(`li.preview-item[data-page-number="${pageNumber}"]`).remove();
    });
  }

  showAlert(alertType, message) {
    const $flashes = $('#flashes');
    const $alert = $(`<p class=${alertType}>${message}</p>`).css(
      'display',
      'block'
    );
    $flashes.empty().append($alert);
    setTimeout(function () {
      $alert.fadeOut(400, function () {
        $(this).remove();
      });
    }, 3000);
  }
}
