$.fn.file_selector = function () {
  return this.each(function () {
    return new FileSelector(this);
  });
};

class FileSelector {
  constructor(containerSelector) {
    this.$container = $(containerSelector);
    this.$rightContainer = $('#preview-list');
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
      onChoose: (e) => this.handleChoose(e),
      onStart: (e) => this.handleSortingStart(e),
      onEnd: (e) => this.handleSortingEnd(e),
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
    $this.toggleOverlay();

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
        $this.toggleOverlay();
      },
      error: function (xhr, status, error) {
        $this.toggleOverlay();
        $this.showAlert('error', 'Failed to delete files!');
        console.error('Delete failed:', status, error);
      },
    });
  }

  handleChoose(e) {
    const $item = $(e.item);
    const originalIndex = $item.index() + 1;
    $item.data('original-index', originalIndex);
  }

  handleSortingStart(e) {
    const selectedItems = this.$items.filter('.selected');
    selectedItems.each(function () {
      const itemIndex = $(this).index() + 1;
      $(this).data('original-index', itemIndex);
    });
  }

  handleSortingEnd(e) {
    this.$items = this.$container.children('li');
    const movedItems = [];

    this.$items.each((index, item) => {
      const newIndex = index + 1;
      const $item = $(item);
      const originalIndex = $item.data('original-index');

      if (originalIndex !== undefined && originalIndex !== newIndex) {
        movedItems.push({
          id: $item.data('imageId'),
          position: newIndex,
        });
      }

      $item.removeData('original-index');
    });

    if (movedItems.length === 0) return;

    const eventId = this.$container.data('eventId');
    const url = '/thumbnails/reposition';

    const $this = this;
    $this.showAlert('notice', 'Sorting files...');
    this.toggleOverlay();

    $.ajax({
      url,
      type: 'PUT',
      data: JSON.stringify({
        event_id: eventId,
        reordered_items: movedItems,
      }),
      contentType: 'application/json',
      success: () => {
        $this.reorderRightPanel();
        $this.setPageNumbers();
        $this.showAlert('notice', 'Files sorted successfully.');
        $this.toggleOverlay();
      },
      error: () => {
        $this.toggleOverlay();
        $this.showAlert('alert', 'Failed to sort files!');
      },
    });
  }

  removePages(pageNumbers) {
    pageNumbers.forEach((pageNumber) => {
      $(`li.preview-item[data-page-number="${pageNumber}"]`).remove();
    });
  }

  reorderRightPanel() {
    const orderedPageNumbers = this.$container
      .children('li')
      .map(function () {
        return $(this).data('page-number');
      })
      .get();

    const $previewMap = {};
    this.$rightContainer.children().each(function () {
      const $el = $(this);
      $previewMap[$el.data('page-number')] = $el;
    });

    const $fragment = $(document.createDocumentFragment());
    orderedPageNumbers.forEach((pageNumber) => {
      const $preview = $previewMap[pageNumber];
      if ($preview) $fragment.append($preview);
    });

    this.$rightContainer.append($fragment);
  }

  setPageNumbers() {
    var items = this.$container.children('li');
    for (var i = 0; i < items.length; i++) {
      $(items[i])
        .find('.page-number')
        .html(i + 1);
    }
  };

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
    }, 5000);
  }

  toggleOverlay() {
    $('body').toggleClass('overlay-active');
  }
}
