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

  $(document).on('click', '.download-combine-pdf', function (e) {
    e.preventDefault();

    const eventId = $('#thumbnail-list').data('event-id');
    $('body').addClass('overlay-active');

    $.ajax({
      type: 'POST',
      url: `/events/${eventId}/generate-pdf`,
      dataType: 'json',
      success: function (response) {
        $('body').removeClass('overlay-active');
        if (response.success) {
          // trigger download from second endpoint
          window.location.href = `/events/${eventId}/download-pdf`;
        } else {
          alert('PDF generation failed.');
        }
      },
      error: function (xhr, status, error) {
        $('body').removeClass('overlay-active');
        console.error('PDF generation error:', error);
        alert('Something went wrong while generating the PDF.');
      },
    });
  });

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

  function syncPanelsOnScroll() {
    const $previewList = $('#preview-list');
    const rightPanelHeight = $previewList.outerHeight();
    const rightPanelScrollTop = $previewList.scrollTop();

    let activeItemFound = false; // Flag to track if an active item is found

    $rightPanel.find('.preview-item').each(function () {
      const $item = $(this);
      const itemHeight = $item.outerHeight();
      const itemTop = $item.position().top;
      const itemBottom = itemTop + itemHeight;

      // Check if the item is in the viewport (visible in the right panel)
      if (
        rightPanelScrollTop + rightPanelHeight >= itemTop + 70 &&
        rightPanelScrollTop <= itemBottom - 70
      ) {
        const pageNumber = $item.data('page-number');

        // Only activate the first item that is visible in the viewport
        if (!activeItemFound) {
          console.log('atciedd');
          // Find the corresponding left panel item
          const $correspondingLeftItem = $leftPanel.find(
            `.thumbnail-item[data-page-number="${pageNumber}"]`
          );

          // If the corresponding item is found, activate it
          if ($correspondingLeftItem.length) {
            // Deactivate all other items in the left panel
            $leftPanel.find('.thumbnail-item').removeClass('active');

            // Activate the current item in the left panel
            $correspondingLeftItem.addClass('active');

            // Scroll the left panel if needed
            const leftPanelHeight = $leftPanel.outerHeight();
            const leftPanelScrollTop = $leftPanel.scrollTop();
            const leftItemTop = $correspondingLeftItem.position().top;
            const leftItemBottom =
              leftItemTop + $correspondingLeftItem.outerHeight();

            // Scroll left panel if the active item is not in view
            if (leftItemTop < leftPanelScrollTop) {
              $leftPanel.scrollTop(leftItemTop); // Scroll up to the active item
            } else if (leftItemBottom > leftPanelScrollTop + leftPanelHeight) {
              $leftPanel.scrollTop(
                leftPanelScrollTop + leftItemBottom - leftPanelHeight
              ); // Scroll down to the active item
            }

            activeItemFound = true; // Set the flag to true to stop further activation
          }
        }
      } else {
        // If the item is fully out of view, we should switch to the next one
        const pageNumber = $item.data('page-number');
        console.log(pageNumber);
        const $correspondingLeftItem = $leftPanel.find(
          `.thumbnail-item[data-page-number="${pageNumber}"]`
        );

        if (
          $correspondingLeftItem.length &&
          $item.position().top + $item.outerHeight() < 0
        ) {
          // If current item is fully out of view, activate the next one
          const nextItem = $rightPanel.find(
            `.preview-item[data-page-number="${pageNumber + 1}"]`
          );
          if (nextItem.length) {
            const nextPageNumber = nextItem.data('page-number');
            const $correspondingNextLeftItem = $leftPanel.find(
              `.thumbnail-item[data-page-number="${nextPageNumber}"]`
            );

            // Deactivate all other items in the left panel
            $leftPanel.find('.thumbnail-item').removeClass('active');

            // Activate the next item
            if ($correspondingNextLeftItem.length) {
              $correspondingNextLeftItem.addClass('active');
            }
          }
        }
      }
    });

    // If no active item is found, we might need to ensure the last item is marked active when scroll completes
    if (!activeItemFound) {
      const lastPreviewItem = $rightPanel.find('.preview-item').last();
      const pageNumber = lastPreviewItem.data('page-number');
      const $correspondingLeftItem = $leftPanel.find(
        `.thumbnail-item[data-page-number="${pageNumber}"]`
      );

      // If the corresponding left item is found, activate it
      if ($correspondingLeftItem.length) {
        $leftPanel.find('.thumbnail-item').removeClass('active');
        $correspondingLeftItem.addClass('active');
      }
    }
  }

  // Add a scroll event listener to the right panel
  $rightPanel.on('scroll', syncPanelsOnScroll);
});
