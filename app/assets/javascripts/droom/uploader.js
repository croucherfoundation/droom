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

      Droploader.prototype.readFiles = function(files) {
        var file, i, len, results;
        if (files) {
          results = [];
          for (i = 0, len = files.length; i < len; i++) {
            file = files[i];
            results.push(this.uploadFile(file));
          }
          return results;
        }
      };

      Droploader.prototype.uploadFile = function(file) {
        return new Upload({
          file: file,
          queue: this._queue,
          url: this._url,
          callback: this.finishUpload
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
          return this._li.addClass('waiting');
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