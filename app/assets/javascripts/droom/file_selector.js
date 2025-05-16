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
    this.historyStack = [];

    const isWindows = /Windows/.test(navigator.userAgent);
    this.superKey = isWindows ? 'ctrl' : 'meta';

    this.initEvents();
    this.initSortable();
  }

  initEvents() {
    this.$container.on('click', 'li', (e) => this.handleClick(e));

    $(document).on('click', '.save-combine-pdf', (e) => this.saveDocument(e));
    $(document).on('click', '.download-combine-pdf', (e) => this.downloadDocument(e));

    $(document).on('keydown', (e) => {
      const isSuperKey = this.superKey === 'ctrl' ? e.ctrlKey : e.metaKey;

      if (e.key === 'Delete' || e.key === 'Backspace') {
        this.deleteSelected();
      } else if (isSuperKey && e.key.toLowerCase() === 'z') {
        e.preventDefault();
        this.undoLastAction();
      }
    });
  }

  initSortable() {
    new Sortable(this.$container[0], {
      multiDrag: true,
      selectedClass: 'selected',
      animation: 150,
      fallbackTolerance: 3,
      multiDragKey: this.superKey,
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
    const selected = this.$items.filter('.selected');

    if (selected.length === 0) {
      this.showAlert('error', 'Select files to delete!');
      return;
    }

    const deletedData = selected
      .map((_, el) => {
        const $el = $(el);
        const index = $el.index();
        const pageNumber = $el.data('page-number');
        const $preview = this.$rightContainer
          .children(`li[data-page-number="${pageNumber}"]`)
          .first();
        const previewIndex = $preview.index();

        return {
          pageNumber,
          index,
          previewIndex,
        };
      })
      .get();

    this.historyStack.push({ type: 'delete', items: deletedData });

    deletedData.forEach(({ pageNumber }) => {
      this.$container
        .children(`li[data-page-number="${pageNumber}"]`)
        .addClass('deleted')
        .removeClass('selected');
      this.$rightContainer
        .children(`li[data-page-number="${pageNumber}"]`)
        .addClass('deleted');
    });

    this.$items = this.$container.children('li');
    this.reorderRightPanel();
    this.setPageNumbers();
  }

  handleChoose(e) {
    const $item = $(e.item);
    const originalIndex = $item.index() + 1;
    $item.data('original-index', originalIndex);
  }

  handleSortingStart(e) {
    const currentOrder = this.$items
      .map(function () {
        return $(this).data('page-number');
      })
      .get();

    this.historyStack.push({ type: 'sort', order: currentOrder });

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

    this.reorderRightPanel();
    this.setPageNumbers();
  }

  undoLastAction() {
    if (this.historyStack.length === 0) {
      this.showAlert('error', 'Nothing to undo!');
      return;
    }

    const lastAction = this.historyStack.pop();

    if (lastAction.type === 'sort') {
      this.undoSort(lastAction.order);
    } else if (lastAction.type === 'delete') {
      this.undoDelete(lastAction.items);
    }
  }

  undoSort(previousOrder) {
    const $itemsMap = {};

    this.$items.each(function () {
      const $el = $(this);
      $itemsMap[$el.data('page-number')] = $el;
    });

    const $fragment = $(document.createDocumentFragment());
    previousOrder.forEach((pageNumber) => {
      if ($itemsMap[pageNumber]) {
        $fragment.append($itemsMap[pageNumber]);
      }
    });

    this.$container.append($fragment);
    this.$items = this.$container.children('li');

    this.reorderRightPanel();
    this.setPageNumbers();
  }

  undoDelete(deletedItems) {
    deletedItems.forEach(({ pageNumber }) => {
      this.$container.children(`li[data-page-number="${pageNumber}"]`).show();
      this.$rightContainer
        .children(`li[data-page-number="${pageNumber}"]`)
        .removeClass('deleted');
    });

    this.$items = this.$container.children('li');
    this.reorderRightPanel();
    this.setPageNumbers();
  }

  saveDocument(e) {
    e.preventDefault();

    const $container = this.$container;
    const eventId = $container.data('eventId');

    var deletedItemIds = $container
      .children('li.deleted')
      .map(function (index, item) {
        return $(item).data('imageId');
      })
      .get();

    var remainingItems = $container
      .children('li')
      .filter(function () {
        return !$(this).hasClass('deleted');
      })
      .map(function (index, item) {
        return {
          id: $(item).data('imageId'),
          position: index + 1,
        };
      })
      .get();

    if (!this.historyStack.length > 0) {
      deletedItemIds = [];
      remainingItems = [];
    }

    const url = `/events/${eventId}/build-compile-pdf`;
    const $this = this;

    $this.showAlert('notice', 'Saving document...');
    $this.toggleOverlay();

    $.ajax({
      url: url,
      type: 'POST',
      data: JSON.stringify({
        deleted_items: deletedItemIds,
        remaining_items: remainingItems,
      }),
      contentType: 'application/json',
      success: () => {
        $this.showAlert('notice', 'Document saved successfully.');
        $this.toggleOverlay();
        location.reload();
      },
      error: () => {
        $this.toggleOverlay();
        $this.showAlert('alert', 'Failed to save document!');
      },
    });
  }

  downloadDocument(e) {
    e.preventDefault();
    
    const eventId = this.$container.data('eventId');
    const url = `/events/${eventId}/generate-pdf`;
    const $this = this;

    $this.showAlert('notice', 'Downloading document...');
    
    $.ajax({
      url: url,
      type: 'POST',
      contentType: 'application/json',
      success: () => {
        $this.showAlert('notice', 'Document downloaded successfully.');
        window.location.href = `/events/${eventId}/download-pdf`;
      },
      error: () => {
        $this.showAlert('alert', 'Failed to download document!');
      },
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
    var items = this.$container.children('li').not('.deleted');
    for (var i = 0; i < items.length; i++) {
      $(items[i])
        .find('.page-number')
        .html(i + 1);
    }
  }

  showAlert(alertType, message) {
    const $flashes = $('#flashes');
    const $alert = $(`<p class="${alertType}" style="margin-bottom: 5px">${message}</p>`).css('display', 'block');
    $flashes.append($alert); 
    setTimeout(() => {
      $alert.fadeOut(400, function () {
        $(this).remove();
      });
    }, 5000);
  }

  toggleOverlay() {
    $('body').toggleClass('overlay-active');
  }
}
