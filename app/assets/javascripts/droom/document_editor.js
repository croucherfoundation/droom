function DocumentEditorForm(e) {
  e.preventDefault();

  var form = e.target;
  var formData = new FormData(e.target);
  var replacedId = $('#document_id').val();

  $.ajax({
    url: form.action,
    type: 'PUT',
    success: function(data) {
      var element = $(`#document_${replacedId}`);
      var filename = data.name;
      var extension = filename.split('.')[1];
      var shortname = filename;

      if (filename.length > 10) {
        shortname = filename.substring(0, 25) + "...";
      }

      var styles = '';
      if (extension == 'pdf') {
        styles = {
          'background-position': '0 -48px',
          'color': 'red'
        }
      } else if (extension == 'doc' || extension == 'docx') {
        styles = {
          'background-position': '0 -96px',
          'color': '#1683ab'
        }
      } else if (extension == 'xls' || extension == 'xlsx') {
        styles = {
          'background-position': '0 -144px',
          'color': '#369620'
        }
      } else if (extension == 'mp4' || extension == 'mov' || extension == 'ogg') {
        styles = {
          'background-position': '0 -192px',
          'color': '#642195'
        }
      }

      element.find('a.document').attr('herf', `/folders/${data.folder_id}/documents/${data.id}`);
      element.find('a.document').addClass(extension).css(styles)
      element.find('span.shortened').attr('title', data.file_file_name).text(shortname);

      $('.popup .closer').click();

      element.css('background-color', '#acebb1')
      setTimeout(function(){
          element.css('background-color', '');
       }, 1000);
    },
    data: formData,
    cache: false,
    contentType: false,
    processData: false
  }).fail(function (jqXHR, textStatus, error) {
    $('p.error').text(jqXHR.responseText)
  });
}
