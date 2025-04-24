$(document).ready(function () {
  const eventId = $("#thumbnail-list").data("event-id");

  $(".upload-slot").each(function () {
    const $uploadSlot = $(this); // <li>
    const $uploadWrapper = $uploadSlot.find(".upload-wrapper"); // <div>
    const $fileInput = $uploadWrapper.find(".upload-input"); // <input>

    // 🖱️ Click to upload
    $uploadWrapper.on("click", function (e) {
      // Prevent click event propagation if it's on the input element itself
      if ($(e.target).is(".upload-input")) {
        return; // Do nothing if we clicked directly on the input
      }
      e.preventDefault();
      e.stopPropagation();
      $fileInput.trigger("click"); // Trigger file input click if clicked outside the input
    });

    // 📂 Handle file input change
    $fileInput.on("change", function () {
      const file = this.files[0];
      if (file) uploadPDF(file);
    });

    // 🐭 Drag over
    $uploadSlot.on("dragover", function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.addClass("drag-over");
    });

    // 🐭 Drag leave
    $uploadSlot.on("dragleave", function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.removeClass("drag-over");
    });

    // 📥 Drop PDF
    $uploadSlot.on("drop", function (e) {
      e.preventDefault();
      e.stopPropagation();
      $uploadSlot.removeClass("drag-over");

      const file = e.originalEvent.dataTransfer.files[0];
      if (file && file.type === "application/pdf") {
        uploadPDF(file);
      } else {
        alert("Please upload a valid PDF file.");
      }
    });
  });

  // 📤 Upload logic
  function uploadPDF(file) {
    $('body').addClass('overlay-active');
    const formData = new FormData();
    formData.append("file", file);

    $.ajax({
      url: `/events/${eventId}/upload-pdf`,
      type: "POST",
      headers: {
        "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content")
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
        alert("PDF upload failed.");
      }
    });
  }

  $(document).on('click', '.download-combine-pdf', function(e) {
    e.preventDefault();
  
    const eventId = $('#thumbnail-list').data('event-id');
    $('body').addClass('overlay-active');

    $.ajax({
      type: 'POST',
      url: `/events/${eventId}/download-pdf`,
      dataType: 'json',
      success: function(response) {
        if (response.file_url) {
          $('body').removeClass('overlay-active');
          window.location.href = response.file_url;
        } else {
          $('body').removeClass('overlay-active');
          alert('PDF download failed.');
        }
      },
      error: function(xhr, status, error) {
        console.error('Download PDF error:', error);
        alert('Something went wrong. Try again.');
      }
    });
  });  
});
