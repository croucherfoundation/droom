(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Ed.Views.AssetInserter = (function(superClass) {
    extend(AssetInserter, superClass);

    function AssetInserter() {
      this.hide = bind(this.hide, this);
      this.show = bind(this.show, this);
      this.place = bind(this.place, this);
      this.insert = bind(this.insert, this);
      this.addBlocks = bind(this.addBlocks, this);
      this.addButton = bind(this.addButton, this);
      this.addQuote = bind(this.addQuote, this);
      this.addVideo = bind(this.addVideo, this);
      this.addImage = bind(this.addImage, this);
      this.toggleButtons = bind(this.toggleButtons, this);
      this.followCaret = bind(this.followCaret, this);
      this.attendTo = bind(this.attendTo, this);
      this.onRender = bind(this.onRender, this);
      return AssetInserter.__super__.constructor.apply(this, arguments);
    }

    AssetInserter.prototype.template = "ed/inserter";

    AssetInserter.prototype.tagName = "div";

    AssetInserter.prototype.className = "ed-inserter";

    AssetInserter.prototype.ui = {
      adders: "a.add"
    };

    AssetInserter.prototype.events = {
      "click a.show": "toggleButtons",
      "click a.image": "addImage",
      "click a.video": "addVideo",
      "click a.quote": "addQuote",
      "click a.button": "addButton",
      "click a.blocks": "addBlocks"
    };

    AssetInserter.prototype.onRender = function() {
      var permitted_insertions;
      this._p = null;
      permitted_insertions = _ed.config('insertions');
      return this.ui.adders.each((function(_this) {
        return function(i, el) {
          var $el;
          $el = $(el);
          if (permitted_insertions.indexOf($el.data('insert')) === -1) {
            return $el.hide();
          }
        };
      })(this));
    };

    AssetInserter.prototype.attendTo = function($el) {
      this._target_el = $el;
      this.$el.appendTo($('body'));
      return this._target_el.on("click keyup focus", this.followCaret);
    };

    AssetInserter.prototype.followCaret = function(e) {
      var current, range, selection;
      selection = this.el.ownerDocument.getSelection();
      if (!selection || selection.rangeCount === 0) {
        current = $(e.target);
      } else {
        range = selection.getRangeAt(0);
        current = $(range.commonAncestorContainer);
      }
      this._p = current.closest('p');
      if (this._p.length && (this.isBlank(this._p.text()) || this._p.text() === "​")) {
        return this.show(this._p);
      } else {
        return this.hide();
      }
    };

    AssetInserter.prototype.toggleButtons = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      if (this.$el.hasClass('showing')) {
        this.trigger('contract');
        return this.$el.removeClass('showing');
      } else {
        this.trigger('expand');
        return this.$el.addClass('showing');
      }
    };

    AssetInserter.prototype.addImage = function() {
      return this.insert(new Ed.Views.Image);
    };

    AssetInserter.prototype.addVideo = function() {
      return this.insert(new Ed.Views.Video);
    };

    AssetInserter.prototype.addQuote = function() {
      return this.insert(new Ed.Views.Quote);
    };

    AssetInserter.prototype.addButton = function() {
      return this.insert(new Ed.Views.Button);
    };

    AssetInserter.prototype.addBlocks = function() {
      return this.insert(new Ed.Views.Blocks);
    };

    AssetInserter.prototype.insert = function(view) {
      if (this._p) {
        this._p.before(view.el);
      } else {
        this._target_el.append(view.el);
        this._target_el.append($("<p />"));
      }
      view.render();
      if (typeof view.focus === "function") {
        view.focus();
      }
      this._target_el.trigger('input');
      return this.hide();
    };

    AssetInserter.prototype.place = function($el) {
      var position;
      position = $el.offset();
      return this.$el.css({
        top: position.top - 10,
        left: position.left - 32
      });
    };

    AssetInserter.prototype.show = function() {
      this.place(this._p);
      this.$el.show();
      return this._target_el.parents('.scroller').on('scroll', (function(_this) {
        return function() {
          return _this.place(_this._p);
        };
      })(this));
    };

    AssetInserter.prototype.hide = function() {
      this.$el.hide();
      this.$el.removeClass('showing');
      return this._target_el.parents('.scroller').off('scroll');
    };

    return AssetInserter;

  })(Ed.View);

  Ed.Views.AssetEditor = (function(superClass) {
    extend(AssetEditor, superClass);

    function AssetEditor() {
      this.closeOtherHelpers = bind(this.closeOtherHelpers, this);
      this.closeHelpers = bind(this.closeHelpers, this);
      this.pickFile = bind(this.pickFile, this);
      this.lookNormal = bind(this.lookNormal, this);
      this.lookAvailable = bind(this.lookAvailable, this);
      this.readFile = bind(this.readFile, this);
      this.catchFiles = bind(this.catchFiles, this);
      this.dragOver = bind(this.dragOver, this);
      this.setStyle = bind(this.setStyle, this);
      this.setSize = bind(this.setSize, this);
      this.update = bind(this.update, this);
      this.setModel = bind(this.setModel, this);
      this.addHelpers = bind(this.addHelpers, this);
      this.onRender = bind(this.onRender, this);
      this.initialize = bind(this.initialize, this);
      return AssetEditor.__super__.constructor.apply(this, arguments);
    }

    AssetEditor.prototype.defaultSize = "full";

    AssetEditor.prototype.stylerView = "AssetStyler";

    AssetEditor.prototype.importerView = "AssetImporter";

    AssetEditor.prototype.uploaderView = "AssetUploader";

    AssetEditor.prototype.ui = {
      catcher: ".ed-dropmask",
      buttons: ".ed-buttons",
      deleter: "a.delete"
    };

    AssetEditor.prototype.triggers = {
      "click @ui.deleter": "remove"
    };

    AssetEditor.prototype.events = {
      "click @ui.catcher": "closeHelpers",
      "dragenter @ui.catcher": "lookAvailable",
      "dragover @ui.catcher": "dragOver",
      "dragleave @ui.catcher": "lookNormal",
      "drop @ui.catcher": "catchFiles",
      "click @ui.catcher": "pickFile"
    };

    AssetEditor.prototype.initialize = function(opts) {
      var collection_name;
      if (opts == null) {
        opts = {};
      }
      if (this._size == null) {
        this._size = _.result(this, 'defaultSize');
      }
      if (collection_name = this.getOption('collectionName')) {
        this.collection = _ed[collection_name];
      }
      return AssetEditor.__super__.initialize.apply(this, arguments);
    };

    AssetEditor.prototype.onRender = function() {
      this.log("🚜 onRender", this.el);
      this.$el.attr('data-ed', true);
      return this.addHelpers();
    };

    AssetEditor.prototype.addHelpers = function() {
      var importer_view_class, importer_view_class_name, picker_view_class, picker_view_class_name, styler_view_class, styler_view_class_name, uploader_view_class, uploader_view_class_name;
      if (uploader_view_class_name = this.getOption('uploaderView')) {
        if (uploader_view_class = Ed.Views[uploader_view_class_name]) {
          this._uploader = new uploader_view_class({
            collection: this.collection
          });
          this._uploader.$el.appendTo(this.ui.buttons);
          this._uploader.render();
          this.log("🚜 added uploader in", this._uploader.el);
          this._uploader.on("select", this.setModel);
          this._uploader.on("create", this.update);
          this._uploader.on("pick", (function(_this) {
            return function() {
              return _this.closeHelpers();
            };
          })(this));
        }
      }
      if (importer_view_class_name = this.getOption('importerView')) {
        if (importer_view_class = Ed.Views[importer_view_class_name]) {
          this._importer = new importer_view_class({
            collection: this.collection
          });
          this._importer.$el.appendTo(this.ui.buttons);
          this._importer.render();
          this._importer.on("select", this.setModel);
          this._importer.on("create", this.update);
          this._importer.on("open", (function(_this) {
            return function() {
              return _this.closeOtherHelpers(_this._importer);
            };
          })(this));
        }
      }
      if (picker_view_class_name = this.getOption('pickerView')) {
        if (picker_view_class = Ed.Views[picker_view_class_name]) {
          this._picker = new picker_view_class({
            collection: this.collection
          });
          this._picker.$el.appendTo(this.ui.buttons);
          this._picker.render();
          this._picker.on("select", this.setModel);
          this._picker.on("open", (function(_this) {
            return function() {
              return _this.closeOtherHelpers(_this._picker);
            };
          })(this));
        }
      }
      if (_ed.getOption('asset_styles')) {
        if (styler_view_class_name = this.getOption('stylerView')) {
          if (styler_view_class = Ed.Views[styler_view_class_name]) {
            this._styler = new styler_view_class({
              model: this.model
            });
            this._styler.$el.appendTo(this.ui.buttons);
            this._styler.render();
            this._styler.on("styled", this.setStyle);
            return this._styler.on("open", (function(_this) {
              return function() {
                return _this.closeOtherHelpers(_this._styler);
              };
            })(this));
          }
        }
      }
    };

    AssetEditor.prototype.setModel = function(model) {
      var ref;
      this.model = model;
      if ((ref = this._styler) != null) {
        ref.setModel(this.model);
      }
      return this.trigger("select", this.model);
    };

    AssetEditor.prototype.update = function() {
      return this.trigger('update');
    };

    AssetEditor.prototype.setSize = function(size) {
      this._size = size;
      if (this.model) {
        return this.stickit();
      }
    };

    AssetEditor.prototype.setStyle = function(style) {
      var size;
      this.$el.removeClass('right left full').addClass(style);
      size = style === "full" ? "full" : "half";
      this.setSize(size);
      return this.update();
    };

    AssetEditor.prototype.dragOver = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      if (e.originalEvent.dataTransfer) {
        return e.originalEvent.dataTransfer.dropEffect = 'copy';
      }
    };

    AssetEditor.prototype.catchFiles = function(e) {
      var ref;
      this.lookNormal();
      if (e != null ? (ref = e.originalEvent.dataTransfer) != null ? ref.files.length : void 0 : void 0) {
        this.containEvent(e);
        return this.readFile(e.originalEvent.dataTransfer.files);
      } else {
        return console.log("unreadable drop", e);
      }
    };

    AssetEditor.prototype.readFile = function(files) {
      if (this._uploader && files.length) {
        return this._uploader.readLocalFile(files[0]);
      }
    };

    AssetEditor.prototype.lookAvailable = function(e) {
      if (e != null) {
        e.stopPropagation();
      }
      return this.ui.catcher.addClass('droppable');
    };

    AssetEditor.prototype.lookNormal = function(e) {
      if (e != null) {
        e.stopPropagation();
      }
      return this.ui.catcher.removeClass('droppable');
    };

    AssetEditor.prototype.pickFile = function(e) {
      var ref;
      if (e != null) {
        e.preventDefault();
      }
      return (ref = this._uploader) != null ? ref.pickFile(e) : void 0;
    };

    AssetEditor.prototype.closeHelpers = function() {
      return _.each([this._picker, this._importer, this._styler], function(h) {
        return h != null ? h.close() : void 0;
      });
    };

    AssetEditor.prototype.closeOtherHelpers = function(helper) {
      return _.each([this._picker, this._importer, this._styler], function(h) {
        if (h !== helper) {
          return h != null ? h.close() : void 0;
        }
      });
    };

    return AssetEditor;

  })(Ed.View);

  Ed.Views.ImageEditor = (function(superClass) {
    extend(ImageEditor, superClass);

    function ImageEditor() {
      return ImageEditor.__super__.constructor.apply(this, arguments);
    }

    ImageEditor.prototype.template = "ed/image_editor";

    ImageEditor.prototype.pickerView = "ImagePicker";

    ImageEditor.prototype.importerView = "ImageImporter";

    ImageEditor.prototype.uploaderView = "ImageUploader";

    ImageEditor.prototype.collectionName = "images";

    return ImageEditor;

  })(Ed.Views.AssetEditor);

  Ed.Views.MainImageEditor = (function(superClass) {
    extend(MainImageEditor, superClass);

    function MainImageEditor() {
      return MainImageEditor.__super__.constructor.apply(this, arguments);
    }

    MainImageEditor.prototype.template = "ed/main_image_editor";

    return MainImageEditor;

  })(Ed.Views.ImageEditor);

  Ed.Views.VideoEditor = (function(superClass) {
    extend(VideoEditor, superClass);

    function VideoEditor() {
      return VideoEditor.__super__.constructor.apply(this, arguments);
    }

    VideoEditor.prototype.template = "ed/video_editor";

    VideoEditor.prototype.pickerView = "VideoPicker";

    VideoEditor.prototype.importerView = "VideoImporter";

    VideoEditor.prototype.uploaderView = "VideoUploader";

    VideoEditor.prototype.collectionName = "videos";

    return VideoEditor;

  })(Ed.Views.AssetEditor);

  Ed.Views.QuoteEditor = (function(superClass) {
    extend(QuoteEditor, superClass);

    function QuoteEditor() {
      return QuoteEditor.__super__.constructor.apply(this, arguments);
    }

    QuoteEditor.prototype.template = "ed/quote_editor";

    QuoteEditor.prototype.importerView = false;

    QuoteEditor.prototype.uploaderView = false;

    return QuoteEditor;

  })(Ed.Views.AssetEditor);

  Ed.Views.ButtonEditor = (function(superClass) {
    extend(ButtonEditor, superClass);

    function ButtonEditor() {
      return ButtonEditor.__super__.constructor.apply(this, arguments);
    }

    ButtonEditor.prototype.template = "ed/button_editor";

    ButtonEditor.prototype.importerView = false;

    ButtonEditor.prototype.uploaderView = false;

    return ButtonEditor;

  })(Ed.Views.AssetEditor);

  Ed.Views.AssetPicker = (function(superClass) {
    extend(AssetPicker, superClass);

    function AssetPicker() {
      this.setVisibility = bind(this.setVisibility, this);
      this.selectModel = bind(this.selectModel, this);
      this.onOpen = bind(this.onOpen, this);
      this.onRender = bind(this.onRender, this);
      return AssetPicker.__super__.constructor.apply(this, arguments);
    }

    AssetPicker.prototype.tagName = "div";

    AssetPicker.prototype.className = "picker";

    AssetPicker.prototype.listView = "AssetList";

    AssetPicker.prototype.ui = {
      head: ".menu-head",
      body: ".menu-body",
      list: ".pick",
      closer: "a.close"
    };

    AssetPicker.prototype.onRender = function() {
      AssetPicker.__super__.onRender.apply(this, arguments);
      this.setVisibility();
      return this.collection.on('add remove reset', this.setVisibility);
    };

    AssetPicker.prototype.onOpen = function() {
      var list_view_class;
      if (!this._list_view) {
        list_view_class = this.getOption('listView');
        this._list_view = new Ed.Views[list_view_class]({
          collection: this.collection
        });
        this.ui.list.append(this._list_view.el);
        this._list_view.on("select", this.selectModel);
      }
      return this._list_view.render();
    };

    AssetPicker.prototype.selectModel = function(model) {
      this.close();
      return this.trigger("select", model);
    };

    AssetPicker.prototype.setVisibility = function() {
      if (this.collection.length) {
        return this.$el.show();
      } else {
        return this.$el.hide();
      }
    };

    return AssetPicker;

  })(Ed.Views.MenuView);

  Ed.Views.ImagePicker = (function(superClass) {
    extend(ImagePicker, superClass);

    function ImagePicker() {
      return ImagePicker.__super__.constructor.apply(this, arguments);
    }

    ImagePicker.prototype.template = "ed/image_picker";

    ImagePicker.prototype.listView = "ImageList";

    return ImagePicker;

  })(Ed.Views.AssetPicker);

  Ed.Views.VideoPicker = (function(superClass) {
    extend(VideoPicker, superClass);

    function VideoPicker() {
      return VideoPicker.__super__.constructor.apply(this, arguments);
    }

    VideoPicker.prototype.template = "ed/video_picker";

    VideoPicker.prototype.listView = "VideoList";

    return VideoPicker;

  })(Ed.Views.AssetPicker);

  Ed.Views.AssetUploader = (function(superClass) {
    extend(AssetUploader, superClass);

    function AssetUploader() {
      this.badFile = bind(this.badFile, this);
      this.containEvent = bind(this.containEvent, this);
      this.createModel = bind(this.createModel, this);
      this.readLocalFile = bind(this.readLocalFile, this);
      this.getPickedFile = bind(this.getPickedFile, this);
      this.triggerPick = bind(this.triggerPick, this);
      this.pickFile = bind(this.pickFile, this);
      return AssetUploader.__super__.constructor.apply(this, arguments);
    }

    AssetUploader.prototype.template = "ed/asset_uploader";

    AssetUploader.prototype.tagName = "div";

    AssetUploader.prototype.className = "uploader";

    AssetUploader.prototype.ui = {
      label: "label",
      filefield: 'input[type="file"]',
      prompt: ".prompt"
    };

    AssetUploader.prototype.events = {
      "click @ui.filefield": "containEvent",
      "change @ui.filefield": "getPickedFile",
      "click @ui.label": "triggerPick"
    };

    AssetUploader.prototype.pickFile = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      if (e != null) {
        e.stopPropagation();
      }
      this.trigger('pick');
      return this.ui.filefield.click();
    };

    AssetUploader.prototype.triggerPick = function() {
      return this.trigger('pick');
    };

    AssetUploader.prototype.getPickedFile = function(e) {
      var files;
      if (files = this.ui.filefield[0].files) {
        return this.readLocalFile(files[0]);
      }
    };

    AssetUploader.prototype.readLocalFile = function(file) {
      var problem, reader;
      if (file != null) {
        if (problem = this.badFile(file)) {
          return this.complain(problem);
        } else {
          reader = new FileReader();
          reader.onloadend = (function(_this) {
            return function() {
              return _this.createModel(reader.result, file);
            };
          })(this);
          return reader.readAsDataURL(file);
        }
      }
    };

    AssetUploader.prototype.createModel = function(data, file) {
      var model, model_data;
      model_data = {
        file_data: data,
        file_name: file.name,
        file_size: file.size,
        file_type: file.type
      };
      model = this.collection.add(model_data, {
        at: 0
      });
      this.trigger("select", model);
      return model.save().done((function(_this) {
        return function() {
          return _this.trigger("create", model);
        };
      })(this));
    };

    AssetUploader.prototype.containEvent = function(e) {
      return e != null ? e.stopPropagation() : void 0;
    };

    AssetUploader.prototype.badFile = function(file) {
      var matchy, mb, mime_types, nice_size, problem, size_limit;
      problem = false;
      if (size_limit = this.getOption('sizeLimit')) {
        mb = file.size / 1048576;
        if (mb > size_limit) {
          nice_size = Math.floor(mb * 100) / 100;
          problem = "Sorry: there is a limit of " + size_limit + "MB for this type of file and " + file.name + " is <strong>" + nice_size + "MB</strong>.";
        }
      }
      if (mime_types = this.getOption('permittedTypes')) {
        if (!(matchy = _.any(mime_types, function(mt) {
          return file.type.match(mt);
        }))) {
          problem = "Sorry: files of type " + file.type + " are not supported here.";
        }
      }
      return problem;
    };

    return AssetUploader;

  })(Ed.View);

  Ed.Views.ImageUploader = (function(superClass) {
    extend(ImageUploader, superClass);

    function ImageUploader() {
      return ImageUploader.__super__.constructor.apply(this, arguments);
    }

    ImageUploader.prototype.permittedTypes = ["image/jpeg", "image/png", "image/gif"];

    ImageUploader.prototype.sizeLimit = 10;

    return ImageUploader;

  })(Ed.Views.AssetUploader);

  Ed.Views.VideoUploader = (function(superClass) {
    extend(VideoUploader, superClass);

    function VideoUploader() {
      return VideoUploader.__super__.constructor.apply(this, arguments);
    }

    VideoUploader.prototype.permittedTypes = ["video/mp4", "video/ogg", "video/webm"];

    VideoUploader.prototype.sizeLimit = 100;

    Ed.Views.AssetImporter = (function(superClass1) {
      extend(AssetImporter, superClass1);

      function AssetImporter() {
        this.resetForm = bind(this.resetForm, this);
        this.disableForm = bind(this.disableForm, this);
        this.createModel = bind(this.createModel, this);
        return AssetImporter.__super__.constructor.apply(this, arguments);
      }

      AssetImporter.prototype.tagName = "div";

      AssetImporter.prototype.className = "importer";

      AssetImporter.prototype.ui = {
        head: ".menu-head",
        body: ".menu-body",
        url: "input.remote_url",
        button: "a.submit",
        closer: "a.close",
        waiter: "p.waiter"
      };

      AssetImporter.prototype.events = {
        "click @ui.head": "toggleMenu",
        "click @ui.closer": "close",
        "click @ui.button": "createModel"
      };

      AssetImporter.prototype.createModel = function() {
        var model, remote_url;
        if (remote_url = this.ui.url.val()) {
          model = this.collection.add({
            remote_url: remote_url
          });
          this.trigger('select', model);
          this.disableForm();
          return model.save().done((function(_this) {
            return function() {
              _this.trigger('create', model);
              _this.resetForm();
              return _this.close();
            };
          })(this));
        }
      };

      AssetImporter.prototype.disableForm = function() {
        this.ui.url.attr('disabled', true);
        this.ui.button.addClass('waiting');
        return this.ui.waiter.show();
      };

      AssetImporter.prototype.resetForm = function() {
        this.ui.button.removeClass('waiting');
        this.ui.url.removeAttr('disabled');
        this.ui.waiter.hide();
        return this.ui.url.val("");
      };

      return AssetImporter;

    })(Ed.Views.MenuView);

    Ed.Views.ImageImporter = (function(superClass1) {
      extend(ImageImporter, superClass1);

      function ImageImporter() {
        return ImageImporter.__super__.constructor.apply(this, arguments);
      }

      ImageImporter.prototype.template = "ed/image_importer";

      return ImageImporter;

    })(Ed.Views.AssetImporter);

    Ed.Views.VideoImporter = (function(superClass1) {
      extend(VideoImporter, superClass1);

      function VideoImporter() {
        return VideoImporter.__super__.constructor.apply(this, arguments);
      }

      VideoImporter.prototype.template = "ed/video_importer";

      return VideoImporter;

    })(Ed.Views.AssetImporter);

    return VideoUploader;

  })(Ed.Views.AssetUploader);

  Ed.Views.ListedAsset = (function(superClass) {
    extend(ListedAsset, superClass);

    function ListedAsset() {
      this.backgroundUrl = bind(this.backgroundUrl, this);
      this.selectMe = bind(this.selectMe, this);
      this.deleteModel = bind(this.deleteModel, this);
      this.onRender = bind(this.onRender, this);
      return ListedAsset.__super__.constructor.apply(this, arguments);
    }

    ListedAsset.prototype.template = "ed/listed";

    ListedAsset.prototype.tagName = "li";

    ListedAsset.prototype.className = "asset";

    ListedAsset.prototype.ui = {
      img: 'img'
    };

    ListedAsset.prototype.events = {
      "click a.delete": "deleteModel",
      "click a.preview": "selectMe"
    };

    ListedAsset.prototype.bindings = {
      "a.preview": {
        attributes: [
          {
            name: 'style',
            observe: 'icon_url',
            onGet: "backgroundUrl"
          }, {
            name: "class",
            observe: "provider",
            onGet: "providerClass"
          }, {
            name: "title",
            observe: "title"
          }
        ]
      },
      ".file_size": {
        observe: "file_size",
        onGet: "inBytes"
      },
      ".width": {
        observe: "width",
        onGet: "inPixels"
      },
      ".height": {
        observe: "height",
        onGet: "inPixels"
      },
      ".duration": {
        observe: "duration",
        onGet: "inTime"
      }
    };

    ListedAsset.prototype.onRender = function() {
      this.stickit();
      this._progress = new Ed.Views.ProgressBar({
        model: this.model,
        size: 40,
        thickness: 10
      });
      this._progress.$el.appendTo(this.$el);
      return this._progress.render();
    };

    ListedAsset.prototype.deleteModel = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      return this.model.remove();
    };

    ListedAsset.prototype.selectMe = function(e) {
      if (e != null) {
        if (typeof e.preventDefault === "function") {
          e.preventDefault();
        }
      }
      return this.trigger('select', this.model);
    };

    ListedAsset.prototype.backgroundUrl = function(url) {
      if (url) {
        return "background-image: url('" + url + "')";
      } else {
        return "";
      }
    };

    return ListedAsset;

  })(Ed.View);

  Ed.Views.NoListedAsset = (function(superClass) {
    extend(NoListedAsset, superClass);

    function NoListedAsset() {
      return NoListedAsset.__super__.constructor.apply(this, arguments);
    }

    NoListedAsset.prototype.template = "ed/none";

    NoListedAsset.prototype.tagName = "li";

    NoListedAsset.prototype.className = "empty";

    return NoListedAsset;

  })(Ed.View);

  Ed.Views.AssetList = (function(superClass) {
    extend(AssetList, superClass);

    function AssetList() {
      return AssetList.__super__.constructor.apply(this, arguments);
    }

    AssetList.prototype.childView = Ed.Views.ListedAsset;

    AssetList.prototype.emptyView = Ed.Views.NoListedAsset;

    AssetList.prototype.tagName = "ul";

    AssetList.prototype.className = "ed-assets";

    AssetList.prototype.childViewTriggers = {
      'select': 'select'
    };

    return AssetList;

  })(Ed.CollectionView);

  Ed.Views.ImageList = (function(superClass) {
    extend(ImageList, superClass);

    function ImageList() {
      return ImageList.__super__.constructor.apply(this, arguments);
    }

    return ImageList;

  })(Ed.Views.AssetList);

  Ed.Views.VideoList = (function(superClass) {
    extend(VideoList, superClass);

    function VideoList() {
      return VideoList.__super__.constructor.apply(this, arguments);
    }

    return VideoList;

  })(Ed.Views.AssetList);

  Ed.Views.Toolbar = (function(superClass) {
    extend(Toolbar, superClass);

    function Toolbar() {
      this.onRender = bind(this.onRender, this);
      this.initialize = bind(this.initialize, this);
      return Toolbar.__super__.constructor.apply(this, arguments);
    }

    Toolbar.prototype.template = _.noop;

    Toolbar.prototype.className = "ed-toolbar";

    Toolbar.prototype.initialize = function(opts) {
      if (opts == null) {
        opts = {};
      }
      return this.target_el = opts.target;
    };

    Toolbar.prototype.onRender = function() {
      return this._toolbar != null ? this._toolbar : this._toolbar = new MediumEditor(this.target_el, {
        placeholder: false,
        autoLink: true,
        imageDragging: false,
        anchor: {
          customClassOption: null,
          customClassOptionText: 'Button',
          linkValidation: false,
          placeholderText: 'URL...',
          targetCheckbox: false
        },
        anchorPreview: false,
        paste: {
          forcePlainText: false,
          cleanPastedHTML: true,
          cleanReplacements: [],
          cleanAttrs: ['class', 'style', 'dir'],
          cleanTags: ['meta']
        },
        toolbar: {
          updateOnEmptySelection: true,
          allowMultiParagraphSelection: true,
          buttons: [
            {
              name: 'bold',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-bold" viewBox="0 0 16 16"> <path d="M8.21 13c2.106 0 3.412-1.087 3.412-2.823 0-1.306-.984-2.283-2.324-2.386v-.055a2.176 2.176 0 0 0 1.852-2.14c0-1.51-1.162-2.46-3.014-2.46H3.843V13H8.21zM5.908 4.674h1.696c.963 0 1.517.451 1.517 1.244 0 .834-.629 1.32-1.73 1.32H5.908V4.673zm0 6.788V8.598h1.73c1.217 0 1.88.492 1.88 1.415 0 .943-.643 1.449-1.832 1.449H5.907z"/> </svg>'
            }, {
              name: 'italic',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-italic" viewBox="0 0 16 16"> <path d="M7.991 11.674 9.53 4.455c.123-.595.246-.71 1.347-.807l.11-.52H7.211l-.11.52c1.06.096 1.128.212 1.005.807L6.57 11.674c-.123.595-.246.71-1.346.806l-.11.52h3.774l.11-.52c-1.06-.095-1.129-.211-1.006-.806z"/> </svg>'
            }, {
              name: 'anchor',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-link-45deg" viewBox="0 0 16 16"> <path d="M4.715 6.542 3.343 7.914a3 3 0 1 0 4.243 4.243l1.828-1.829A3 3 0 0 0 8.586 5.5L8 6.086a1.002 1.002 0 0 0-.154.199 2 2 0 0 1 .861 3.337L6.88 11.45a2 2 0 1 1-2.83-2.83l.793-.792a4.018 4.018 0 0 1-.128-1.287z"/> <path d="M6.586 4.672A3 3 0 0 0 7.414 9.5l.775-.776a2 2 0 0 1-.896-3.346L9.12 3.55a2 2 0 1 1 2.83 2.83l-.793.792c.112.42.155.855.128 1.287l1.372-1.372a3 3 0 1 0-4.243-4.243L6.586 4.672z"/> </svg>'
            }, {
              name: 'orderedlist',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-list-ol" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M5 11.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5z"/> <path d="M1.713 11.865v-.474H2c.217 0 .363-.137.363-.317 0-.185-.158-.31-.361-.31-.223 0-.367.152-.373.31h-.59c.016-.467.373-.787.986-.787.588-.002.954.291.957.703a.595.595 0 0 1-.492.594v.033a.615.615 0 0 1 .569.631c.003.533-.502.8-1.051.8-.656 0-1-.37-1.008-.794h.582c.008.178.186.306.422.309.254 0 .424-.145.422-.35-.002-.195-.155-.348-.414-.348h-.3zm-.004-4.699h-.604v-.035c0-.408.295-.844.958-.844.583 0 .96.326.96.756 0 .389-.257.617-.476.848l-.537.572v.03h1.054V9H1.143v-.395l.957-.99c.138-.142.293-.304.293-.508 0-.18-.147-.32-.342-.32a.33.33 0 0 0-.342.338v.041zM2.564 5h-.635V2.924h-.031l-.598.42v-.567l.629-.443h.635V5z"/> </svg>'
            }, {
              name: 'unorderedlist',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-list-ul" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M5 11.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm-3 1a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0 4a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0 4a1 1 0 1 0 0-2 1 1 0 0 0 0 2z"/> </svg>'
            }, {
              name: 'h2',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-h2" viewBox="0 0 16 16"> <path d="M7.638 13V3.669H6.38V7.62H1.759V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.022-6.733v-.048c0-.889.63-1.668 1.716-1.668.957 0 1.675.608 1.675 1.572 0 .855-.554 1.504-1.067 2.085l-3.513 3.999V13H15.5v-1.094h-4.245v-.075l2.481-2.844c.875-.998 1.586-1.784 1.586-2.953 0-1.463-1.155-2.556-2.919-2.556-1.941 0-2.966 1.326-2.966 2.74v.049h1.223z"/> </svg>'
            }, {
              name: 'h3',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-type-h3" viewBox="0 0 16 16"> <path d="M7.637 13V3.669H6.379V7.62H1.758V3.67H.5V13h1.258V8.728h4.62V13h1.259zm3.625-4.272h1.018c1.142 0 1.935.67 1.949 1.674.013 1.005-.78 1.737-2.01 1.73-1.08-.007-1.853-.588-1.935-1.32H9.108c.069 1.327 1.224 2.386 3.083 2.386 1.935 0 3.343-1.155 3.309-2.789-.027-1.51-1.251-2.16-2.037-2.249v-.068c.704-.123 1.764-.91 1.723-2.229-.035-1.353-1.176-2.4-2.954-2.385-1.873.006-2.857 1.162-2.898 2.358h1.196c.062-.69.711-1.299 1.696-1.299.998 0 1.695.622 1.695 1.525.007.922-.718 1.592-1.695 1.592h-.964v1.074z"/> </svg>'
            }, {
              name: 'removeFormat',
              contentDefault: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16"> <path fill-rule="evenodd" d="M13.854 2.146a.5.5 0 0 1 0 .708l-11 11a.5.5 0 0 1-.708-.708l11-11a.5.5 0 0 1 .708 0Z"/> <path fill-rule="evenodd" d="M2.146 2.146a.5.5 0 0 0 0 .708l11 11a.5.5 0 0 0 .708-.708l-11-11a.5.5 0 0 0-.708 0Z"/> </svg>'
            }
          ]
        }
      });
    };

    return Toolbar;

  })(Ed.View);

  Ed.Views.AssetStyler = (function(superClass) {
    extend(AssetStyler, superClass);

    function AssetStyler() {
      this.setWide = bind(this.setWide, this);
      this.setFull = bind(this.setFull, this);
      this.setLeft = bind(this.setLeft, this);
      this.setRight = bind(this.setRight, this);
      this.setModel = bind(this.setModel, this);
      this.onRender = bind(this.onRender, this);
      return AssetStyler.__super__.constructor.apply(this, arguments);
    }

    AssetStyler.prototype.tagName = "div";

    AssetStyler.prototype.className = "styler";

    AssetStyler.prototype.template = "ed/styler";

    AssetStyler.prototype.events = {
      "click a.right": "setRight",
      "click a.left": "setLeft",
      "click a.full": "setFull",
      "click a.wide": "setWide",
      "click a.hero": "setHero"
    };

    AssetStyler.prototype.onRender = function() {
      if (this.model) {
        return this.$el.show();
      } else {
        return this.$el.hide();
      }
    };

    AssetStyler.prototype.setModel = function(model) {
      this.model = model;
      return this.render();
    };

    AssetStyler.prototype.setRight = function() {
      return this.trigger("styled", "right");
    };

    AssetStyler.prototype.setLeft = function() {
      return this.trigger("styled", "left");
    };

    AssetStyler.prototype.setFull = function() {
      return this.trigger("styled", "full");
    };

    AssetStyler.prototype.setWide = function() {
      return this.trigger("styled", "wide");
    };

    return AssetStyler;

  })(Ed.View);

  Ed.Views.ImageWeighter = (function(superClass) {
    extend(ImageWeighter, superClass);

    function ImageWeighter() {
      return ImageWeighter.__super__.constructor.apply(this, arguments);
    }

    ImageWeighter.prototype.tagName = "div";

    ImageWeighter.prototype.className = "weighter";

    ImageWeighter.prototype.template = "ed/weighter";

    ImageWeighter.prototype.ui = {
      head: ".menu-head",
      body: ".menu-body"
    };

    ImageWeighter.prototype.events = {
      "click @ui.head": "toggleMenu"
    };

    ImageWeighter.prototype.bindings = {
      "input.weight": "main_image_weighting"
    };

    return ImageWeighter;

  })(Ed.Views.MenuView);

  Ed.Views.ProgressBar = (function(superClass) {
    extend(ProgressBar, superClass);

    function ProgressBar() {
      this.progressLabel = bind(this.progressLabel, this);
      this.showProgress = bind(this.showProgress, this);
      this.initProgress = bind(this.initProgress, this);
      this.setModel = bind(this.setModel, this);
      this.onRender = bind(this.onRender, this);
      return ProgressBar.__super__.constructor.apply(this, arguments);
    }

    ProgressBar.prototype.template = _.noop;

    ProgressBar.prototype.tagName = "span";

    ProgressBar.prototype.className = "ed-progress";

    ProgressBar.prototype.bindings = {
      ":el": {
        observe: "progressing",
        visible: true
      },
      ".label": {
        observe: "progress",
        update: "progressLabel"
      }
    };

    ProgressBar.prototype.onRender = function() {
      var ref;
      this.initProgress();
      if (this.model) {
        this.stickit();
      }
      return (ref = this.model) != null ? ref.on("change:progress", this.showProgress) : void 0;
    };

    ProgressBar.prototype.setModel = function(model) {
      this.model = model;
      return this.render();
    };

    ProgressBar.prototype.initProgress = function() {
      this.$el.append('<div class="label"></div>');
      return this.$el.circleProgress({
        size: this._size,
        thickness: this._thickness,
        fill: {
          color: "rgba(255,255,255,0.9)"
        },
        emptyFill: "rgba(255,255,255,0.2)"
      });
    };

    ProgressBar.prototype.showProgress = function(model, progress) {
      if (!this.$el.data('circle-progress')) {
        this.initProgress();
      }
      if (progress > 1) {
        return this.$el.fadeOut(1000);
      } else {
        if (!this.$el.is(':visible')) {
          this.$el.show();
        }
        return this.$el.circleProgress("value", progress);
      }
    };

    ProgressBar.prototype.progressLabel = function($el, progress, model, options) {
      if (progress > 1) {
        return $el.text("Done");
      } else if (progress <= 0.99) {
        return $el.text((progress * 100) + "%").removeClass('processing');
      } else {
        return $el.html("please wait").addClass('processing');
      }
    };

    return ProgressBar;

  })(Ed.View);

  Ed.Views.Helper = (function(superClass) {
    extend(Helper, superClass);

    function Helper() {
      this.toggle = bind(this.toggle, this);
      this.onRender = bind(this.onRender, this);
      return Helper.__super__.constructor.apply(this, arguments);
    }

    Helper.prototype.template = _.noop;

    Helper.prototype.ui = {
      shower: "a.show",
      help: ".help"
    };

    Helper.prototype.events = {
      "click a.show": "toggle"
    };

    Helper.prototype.onRender = function() {
      return this.stickit();
    };

    Helper.prototype.toggle = function(e) {
      if (this.$el.hasClass('showing')) {
        return this.$el.removeClass('showing');
      } else {
        return this.$el.addClass('showing');
      }
    };

    return Helper;

  })(Ed.View);

}).call(this);