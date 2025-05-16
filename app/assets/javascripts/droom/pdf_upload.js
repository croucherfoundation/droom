$(document).ready(function () {
  const eventId = $('#thumbnail-list').data('event-id');

  $('.upload-slot').each(function () {
    const $uploadSlot = $(this); // <li>
    const $uploadWrapper = $uploadSlot.find('.upload-wrapper'); // <div>
    const $fileInput = $uploadWrapper.find('.upload-input'); // <input>

    // 🖱️ Click to upload
    $uploadWrapper.on('click', function (e) {
      // Prevent click event propagation if it's on the input element itself
      if ($(e.target).is('.upload-input')) {
        return; // Do nothing if we clicked directly on the input
      }
      e.preventDefault();
      e.stopPropagation();
      $fileInput.trigger('click'); // Trigger file input click if clicked outside the input
    });

    // 📂 Handle file input change
    $fileInput.on('change', function () {
      const file = this.files[0];
      if (file) uploadPDF(file);
    });

    // 🐭 Drag over
    $uploadSlot.on('dragover', function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.addClass('drag-over');
    });

    // 🐭 Drag leave
    $uploadSlot.on('dragleave', function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.removeClass('drag-over');
    });

    // 📥 Drop PDF
    $uploadSlot.on('drop', function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.removeClass('drag-over');

      const file = e.originalEvent.dataTransfer.files[0];
      if (file && file.type === 'application/pdf') {
        uploadPDF(file);
      } else {
        alert('Please upload a valid PDF file.');
      }
    });
  });

  // 📤 Upload logic
  function uploadPDF(file) {
    $('body').addClass('overlay-active');
    const formData = new FormData();
    formData.append('file', file);

    $.ajax({
      url: `/events/${eventId}/upload-pdf`,
      type: 'POST',
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content'),
      },
      data: formData,
      contentType: false,
      processData: false,
      success: function () {
        $('body').removeClass('overlay-active');
        location.reload();
      },
      error: function () {
        $('body').removeClass('overlay-active');
        alert('PDF upload failed.');
      },
    });
  }

  $('.preview-item').each(function () {
    const $item = $(this);
    const pdfUrl = $item.data('pdf-url');
    const $canvas = $item.find('canvas')[0];
    const ctx = $canvas.getContext('2d');

    const boost = 1.5; // Set boost for higher resolution
    const baseScale = 1.5; // PDF zoom scale

    // Create Intersection Observer for lazy loading
    const observer = new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          observer.unobserve(entry.target); // Stop observing after it's in view
          renderPDF(entry.target, pdfUrl);
        }
      });
    });

    observer.observe($item[0]);

    // Render PDF function
    function renderPDF(target, pdfUrl) {
      pdfjsLib
        .getDocument(pdfUrl)
        .promise.then(function (pdf) {
          return pdf.getPage(1); // Render first page (you can change if needed)
        })
        .then(function (page) {
          const viewport = page.getViewport({ scale: baseScale });

          // Boost resolution
          const outputScale = (window.devicePixelRatio || 1) * boost;

          // Set internal resolution but keep visual size the same
          $canvas.width = viewport.width * outputScale; // Higher internal resolution
          $canvas.height = viewport.height * outputScale;

          // Keep the same visual display size
          $canvas.style.width = viewport.width + 'px';
          $canvas.style.height = viewport.height + 'px';

          // Adjust context to account for the higher resolution
          ctx.setTransform(outputScale, 0, 0, outputScale, 0, 0);

          // Render PDF page on canvas
          const renderContext = {
            canvasContext: ctx,
            viewport: viewport,
          };

          page.render(renderContext);
        })
        .catch(function (error) {
          console.error('PDF rendering error:', error);
        });
    }
  });

  // Select the left and right panels
  const $leftPanel = $('.left-panel');
  const $rightPanel = $('.preview-area');
  let isScrollingProgrammatically = false;
  let suppressLeftPanelScroll = false;
  let currentActivePage = null;
  
  // Debounce utility
  function debounce(func, wait) {
    let timeout;
    return function (...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }
  
  // Get the first visible preview item based on scroll
  function getVisiblePreviewPageNumber() {
    const panelTop = $rightPanel.offset().top;
    let closestItem = null;
    let minDistance = Infinity;
  
    $rightPanel.find('.preview-item').each(function () {
      const $item = $(this);
      const offsetTop = $item.offset().top;
      const distance = Math.abs(offsetTop - panelTop - 70); // buffer
  
      if (distance < minDistance) {
        minDistance = distance;
        closestItem = $item;
      }
    });
  
    return closestItem ? closestItem.data('page-number') : null;
  }
  
  function syncPanelsOnScroll() {
    if(!shouldScroll()) return;
    if (isScrollingProgrammatically) return;
  
    const visiblePage = getVisiblePreviewPageNumber();
    if (visiblePage && visiblePage !== currentActivePage) {
      currentActivePage = visiblePage;
  
      const $newActive = $leftPanel.find(
        `.thumbnail-item[data-page-number="${visiblePage}"]`
      );
  
      if ($newActive.length) {
        $leftPanel.find('.thumbnail-item').removeClass('active selected');
        $newActive.addClass('active');
        
        if (!suppressLeftPanelScroll) {
          const scrollTop = $newActive.position().top + $leftPanel.scrollTop();
          const itemHeight = $newActive.outerHeight();
          const panelHeight = $leftPanel.outerHeight();
  
          // Only scroll if not fully visible
          if (
            $newActive.position().top < 0 ||
            $newActive.position().top + itemHeight > panelHeight
          ) {
            $leftPanel.scrollTop(scrollTop - panelHeight / 2 + itemHeight / 2);
          }
        }
      }
    }
  }
  
  // Debounced scroll listener
  $rightPanel.on('scroll', debounce(syncPanelsOnScroll, 100));
  
  // Click handler on thumbnails
  $('#thumbnail-list .thumbnail').on('click', function () {
    if(!shouldScroll()) return;

    suppressLeftPanelScroll = true;
  
    const $li = $(this).closest('.thumbnail-item');
    const pageNumber = $li.data('page-number');
  
    currentActivePage = pageNumber;
    $li.addClass('active').siblings().removeClass('active');
    scrollToPDF(pageNumber);
  
    setTimeout(() => {
      suppressLeftPanelScroll = false;
    }, 600);
  });
  
  function scrollToPDF(pageNumber) {
    const $container = $('.preview-area');
    const $targetPDF = $container.find(
      `.preview-item[data-page-number="${pageNumber}"]`
    );
  
    if ($targetPDF.length) {
      const scrollTop =
        $targetPDF.position().top + $container.scrollTop() - 70;
  
      isScrollingProgrammatically = true;
  
      $container.animate({ scrollTop }, 500, () => {
        isScrollingProgrammatically = false;
      });
    } else {
      console.warn('PDF not found for page:', pageNumber);
    }
  } 

  function shouldScroll() {
    const selected = $leftPanel.find('.thumbnail-item.selected');

    if (selected.length > 1) {
      return false;
    } 

    return true;
  }
  

});
