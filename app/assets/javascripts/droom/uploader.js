(function() {
  var Upload,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  jQuery(function($) {
    var Droploader;
    $.fn.droploader = function() {
      return this.each(function() {
        return new Droploader(this);
      });
    };
    return Droploader = (function() {
      function Droploader(element) {
        this.finishUpload = bind(this.finishUpload, this);
        this.lookAvailable = bind(this.lookAvailable, this);
        this.lookNormal = bind(this.lookNormal, this);
        this.blockDragover = bind(this.blockDragover, this);
        this.blockEvent = bind(this.blockEvent, this);
        this.uploadFile = bind(this.uploadFile, this);
        this.readFiles = bind(this.readFiles, this);
        this.catchFiles = bind(this.catchFiles, this);
        this.readFilefield = bind(this.readFilefield, this);
        this.removeSection = bind(this.removeSection, this);
        this.triggerFilefield = bind(this.triggerFilefield, this);
        this.resetFilefield = bind(this.resetFilefield, this);
        this.disable = bind(this.disable, this);
        this.enable = bind(this.enable, this);
        var picker_selector, queue_selector;
        this._catcher = $(element);
        this._active = true;
        this._url = this._catcher.data('droppable');
        this._form = $('<form method="POST" class="droploader" />').addClass('uploader').insertAfter(this._catcher);
        this.resetFilefield();
        if (queue_selector = this._catcher.data('queue')) {
          this._queue = $(queue_selector);
        } else {
          this._queue = this._catcher.find('[data-role="upload-queue"]');
        }
        if (picker_selector = this._catcher.data('picker')) {
          this._triggers = $(picker_selector);
        } else {
          this._triggers = this._catcher.find('[data-role="upload-file"]');
          if (this._triggers.length === 0) {
            // Only attach to standard button if not already used by another droploader
            if (!window.droploaderStandardTriggerAttached) {
              this._triggers = $('.standard-upload-btn');
              window.droploaderStandardTriggerAttached = true;
            } else {
              this._triggers = $();  // Empty set: no trigger for this droploader
            }
          }
        }
        this._triggers.click(this.triggerFilefield);
        this._readers = [];
        this.enable();
        this._catcher.on("sorting", this.disable);
        this._catcher.on("not_sorting", this.enable);
      }

      Droploader.prototype.enable = function() {
        this._active = true;
        this._catcher.on("dragenter", this.lookAvailable);
        return this._catcher.on("drop", this.catchFiles);
      };

      Droploader.prototype.disable = function() {
        this._active = false;
        this._catcher.off("dragenter", this.lookAvailable);
        return this._catcher.off("drop", this.catchFiles);
      };

      Droploader.prototype.resetFilefield = function() {
        var ref;
        if ((ref = this._filefield) != null) {
          ref.remove();
        }
        this._filefield = $('<input type="file" multiple="multiple" />').appendTo(this._form);
        return this._filefield.on("change", this.readFilefield);
      };

      Droploader.prototype.triggerFilefield = function(e) {
        if (e != null) {
          e.preventDefault();
        }
        return this._filefield.click();
      };

      Droploader.prototype.removeSection = function(e) {
        return e != null ? e.preventDefault() : void 0;
      };

      Droploader.prototype.readFilefield = function() {
        this.readFiles(this._filefield[0].files);
        return this.resetFilefield();
      };

      Droploader.prototype.catchFiles = function(e) {
        var ref;
        this.lookNormal();
        if (e != null ? (ref = e.originalEvent.dataTransfer) != null ? ref.files.length : void 0 : void 0) {
          this.blockEvent(e);
          return this.readFiles(e.originalEvent.dataTransfer.files);
        } else {
          return console.log("unreadable drop", e);
        }
      };

      // Droploader.prototype.readFiles = function(files) {
      //   var file, i, len, results;
      //   if (files) {
      //     results = [];
      //     for (i = 0, len = files.length; i < len; i++) {
      //       file = files[i];
      //       // Block script and program files
      //       if (!/^(application\/(x-javascript|javascript|x-msdownload|x-sh|x-exe|x-dosexec|x-bat|x-csh|x-python|x-perl|x-php|x-ruby|x-shellscript)|text\/(javascript|x-python|x-perl|x-php|x-ruby|x-shellscript)|application\/octet-stream)$/i.test(file.type) &&
      //           !/\.(js|exe|sh|bat|py|pl|php|rb|c|cpp|h|java|class|jar|msi|vb|vbs|cmd|scr|ps1)$/i.test(file.name)) {
      //         results.push(this.uploadFile(file));
      //       } else {
      //         // Optionally, show an error or skip silently
      //         alert('Blocked file type: ' + file.name);
      //         console.warn('Blocked file type:', file.name);
      //       }
      //       results.push(this.uploadFile(file));
      //     }
      //     return results;
      //   }
      // };
      Droploader.prototype.readFiles = function(files) {
        if (!files || !files.length) return;
        const allowedMimeTypes = [
          // PDF
          'application/pdf',
          
          // Word documents
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/x-tika-ooxml',
          'application/vnd.oasis.opendocument.text',
          'application/vnd.oasis.opendocument.text-template',
          'application/vnd.oasis.opendocument.text-web',
          'application/vnd.oasis.opendocument.text-master',
          'text/html',
          'application/xml',
          'application/vnd.jgraph.mxfile',
          'application/vnd.jgraph.drawio',
          'application/octet-stream',
          'application/x-xmind',
          
          // PowerPoint presentations
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          
          // Excel spreadsheets
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'text/csv',
          
          // Text files
          'text/plain',
          'text/rtf',
          
          // Email messages
          'message/rfc822',
          'application/vnd.ms-outlook',
          'application/x-msg',
          'text/x-eml',
        
          // Apple files
          'application/vnd.apple.pages',
          'application/vnd.apple.numbers',
          'application/vnd.apple.keynote',
        
          // Video files
          'video/mp4',
          'video/quicktime',
          'video/webm',
        
          // Archive & Storage Files
          'application/zip',
          'application/x-zip-compressed',
          'application/x-rar-compressed',
          'application/x-tar',
          'application/x-7z-compressed',
          'application/x-gzip',
          'application/x-ole-storage',
        
          // Font Files
          'font/ttf',
          'font/otf',
          'font/woff',
          'font/woff2',
        
          // Images
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
          'image/avif',
          'image/webp',
          'image/svg+xml',
          'image/bmp',
          'image/tiff',
          'image/x-icon',
          'image/heic',
          'image/heif',
          'image/vnd.adobe.photoshop'
        ];
        
        const allowedExtensions = /\.(pdf|doc|docx|odt|ott|docm|dot|dotx|dotm|html|htm|xml|mxfile|drawio|xmind|ppt|pptx|xls|xlsx|csv|txt|rtf|eml|msg|pages|numbers|key|mp4|mov|webm|zip|rar|tar|7z|gz|tar\.gz|tgz|ttf|otf|woff|woff2|jpg|jpeg|png|gif|avif|webp|svg|bmp|tiff|ico|heic|heif|psd)$/i;
        
        const isFileSecure = (file) => {
          return allowedMimeTypes.includes(file.type) ||
                allowedExtensions.test(file.name);
        };

        // Maximum file size: 200MB
        const MAX_FILE_SIZE = 200 * 1024 * 1024;
        // Large file threshold for async scanning: 25MB
        const LARGE_FILE_THRESHOLD = 25 * 1024 * 1024;

        const results = [];

        for (let i = 0; i < files.length; i++) {
          const file = files[i];

          if (!isFileSecure(file)) {
            alert('Upload blocked: "' + file.name + '" contains an unsupported file type. Please select a different file.');
            console.warn('Blocked file type:', file.name);
            continue;
          }

          if (file.size > MAX_FILE_SIZE) {
            alert('File too large: "' + file.name + '" (' + (file.size / (1024 * 1024)).toFixed(1) + 'MB). Maximum file size is 200MB.');
            console.warn('File too large:', file.name, file.size);
            continue;
          }

          // Flag large files so the Upload object can show scanning status
          var isLargeFile = file.size > LARGE_FILE_THRESHOLD;
          results.push(this.uploadFile(file, isLargeFile));
        }

        return results;
      };

      Droploader.prototype.uploadFile = function(file, isLargeFile) {
        return new Upload({
          file: file,
          queue: this._queue,
          url: this._url,
          callback: this.finishUpload,
          isLargeFile: isLargeFile || false
        });
      };

      Droploader.prototype.blockEvent = function(e) {
        e.preventDefault();
        return e.stopPropagation();
      };

      Droploader.prototype.blockDragover = function(e) {
        e.preventDefault();
        if (e.originalEvent.dataTransfer) {
          return e.originalEvent.dataTransfer.dropEffect = 'copy';
        }
      };

      Droploader.prototype.lookNormal = function() {
        return this._catcher.removeClass('droppable');
      };

      Droploader.prototype.lookAvailable = function() {
        if (!this._mask) {
          this._mask = $('<div class="dropmask" />').appendTo(this._catcher);
          this._mask.on("dragover", this.blockDragover);
          this._mask.on("drop", this.catchFiles);
          this._mask.on("dragleave", this.lookNormal);
        }
        return this._catcher.addClass('droppable');
      };

      Droploader.prototype.finishUpload = function(upload, el) {
        var target_selector;
        if (target_selector = this._catcher.data('refreshes')) {
          return $(target_selector).refresh();
        }
      };

      return Droploader;

    })();
  });

  Upload = (function() {
    function Upload(opts) {
      this.cancel = bind(this.cancel, this);
      this.error = bind(this.error, this);
      this.success = bind(this.success, this);
      this.stateChange = bind(this.stateChange, this);
      this.showProgress = bind(this.showProgress, this);
      this.sendData = bind(this.sendData, this);
      this.previewImage = bind(this.previewImage, this);
      this.prepProgress = bind(this.prepProgress, this);
      this.prepXhr = bind(this.prepXhr, this);
      this.readFile = bind(this.readFile, this);
      this._options = opts;
      this._file = opts.file;
      this._queue = opts.queue;
      this._url = opts.url;
      this._callback = opts.callback;
      this._isLargeFile = opts.isLargeFile || false;
      console.log("Upload", opts);
      if (this._file && this._url) {
        this.readFile();
        this.prepXhr();
        this.prepProgress();
        this.sendData();
      }
    }

    Upload.prototype.readFile = function() {
      this._mime = this._file.type;
      if (this._filename == null) {
        this._filename = this._file.name.split(/[\/\\]/).pop();
      }
      return this._ext = this._file.name.split('.').pop();
    };

    Upload.prototype.prepXhr = function() {
      var csrf_token;
      this._xhr = new XMLHttpRequest();
      this._xhr.withCredentials = true;
      this._xhr.upload.onprogress = this.showProgress;
      this._xhr.onreadystatechange = this.stateChange;
      this._xhr.open('POST', this._url, true);
      this._xhr.setRequestHeader('X-PJAX', 'true');
      if (csrf_token = $('meta[name="csrf-token"]').attr('content')) {
        return this._xhr.setRequestHeader('X-CSRF-Token', csrf_token);
      }
    };

    Upload.prototype.prepProgress = function() {
      var thumbnail;
      this._li = $('<li class="uploading"></li>').addClass(this._ext).appendTo(this._queue);
      this._label_holder = $('<span class="label"></span>').appendTo(this._li);
      this._label = $('<span class="filename"></span>').text(this._filename).appendTo(this._label_holder);
      if (this._mime.substr(0, 5) === "image") {
        thumbnail = $('<img class="thumbnail" />').prependTo(this._label_holder);
        this.previewImage(thumbnail);
      } else {
        $('<span class="file" />').prependTo(this._label_holder);
      }
      this._progress_holder = $('<span class="progress"></span>').appendTo(this._li);
      this._bar = $('<span class="bar"></span>').appendTo(this._progress_holder);
      this._canceller = $('<a class="cancel minimal"></a>').appendTo(this._li);
      this._waiter = $('<span class="waiting"></a>').appendTo(this._li);
      this._w = this._progress_holder.width();
      return this._canceller.click(this.cancel);
    };

    Upload.prototype.previewImage = function(img) {
      return console.log("previewImage in", img);
    };

    Upload.prototype.sendData = function() {
      var form_data;
      form_data = new FormData();
      form_data.append("document[name]", this._filename);
      form_data.append("document[file]", this._file);
      return this._xhr.send(form_data);
    };

    Upload.prototype.showProgress = function(e) {
      var prog;
      if (e.lengthComputable) {
        prog = e.loaded / e.total;
        this._bar.width(Math.round(this._w * prog));
        if (prog > 0.99) {
          this._li.addClass('waiting');
          // For large files, show that virus scanning will happen in background
          if (this._isLargeFile) {
            this._label.text(this._filename + ' — processing, virus scan will run in background...');
          }
        }
      }
    };

    Upload.prototype.stateChange = function() {
      if (this._xhr.readyState === 4) {
        if (this._xhr.status === 200) {
          this._bar.width(this._w);
          return this.success(this._xhr.responseText);
        } else {
          return this.error();
        }
      }
    };

    Upload.prototype.success = function(response) {
      var base, confirmation;
      if (typeof (base = this._options).on_success === "function") {
        base.on_success(response);
      }
      confirmation = $(response);
      confirmation.activate();
      this._li.after(confirmation);
      this._li.remove();

      // Check if the document is pending virus scan (large file async scan)
      var scanStatus = confirmation.data('scan-status') || confirmation.attr('data-scan-status');
      if (scanStatus === 'pending') {
        var scanBadge = confirmation.find('.scan-status.scanning');
        if (scanBadge.length === 0) {
          confirmation.append('<span class="scan-status scanning" title="File is being scanned for viruses">⏳ Scanning...</span>');
        }
      }

      confirmation.signal_confirmation();
      return typeof this._callback === "function" ? this._callback(this, confirmation) : void 0;
    };

    Upload.prototype.error = function() {
      var base, msg;
      console.log("error", this._xhr);
      msg = this._xhr.response ? this._xhr.response : this._.statusText;
      if (typeof (base = this._options).on_error === "function") {
        base.on_error();
      }
      this._li.addClass('erratic');
      this._li.append($('<span class="error" />').text(msg));
      this._li.append($('<span class="delete" style="background-color: inherit;" />').text('x'));
      $('.delete').on('click', function() {
        return $('.uploading').css('display', 'none');
      });
      return this._li.signal_error();
    };

    Upload.prototype.cancel = function() {
      var base;
      this._xhr.abort();
      if (typeof (base = this._options).on_cancel === "function") {
        base.on_cancel();
      }
      return this._li.fadeOut(function() {
        return $(this).remove();
      });
    };

    return Upload;

  })();

}).call(this);