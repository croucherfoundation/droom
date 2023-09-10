(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Ed.Views.ListedAsset = (function(superClass) {
    extend(ListedAsset, superClass);

    function ListedAsset() {
      this.backgroundUrl = bind(this.backgroundUrl, this);
      this.selectMe = bind(this.selectMe, this);
      this.deleteMe = bind(this.deleteMe, this);
      return ListedAsset.__super__.constructor.apply(this, arguments);
    }

    ListedAsset.prototype.template = "ed/listed";

    ListedAsset.prototype.tagName = "li";

    ListedAsset.prototype.className = "asset";

    ListedAsset.prototype.events = {
      "click a.delete": "deleteMe",
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
      }
    };

    ListedAsset.prototype.deleteMe = function(e) {
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

  Ed.Views.AssetList = (function(superClass) {
    extend(AssetList, superClass);

    function AssetList() {
      return AssetList.__super__.constructor.apply(this, arguments);
    }

    AssetList.prototype.childView = Ed.Views.ListedAsset;

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

  Ed.Views.Asset = (function(superClass) {
    extend(Asset, superClass);

    function Asset() {
      this.setModel = bind(this.setModel, this);
      this.remove = bind(this.remove, this);
      this.update = bind(this.update, this);
      this.addEditor = bind(this.addEditor, this);
      this.onRender = bind(this.onRender, this);
      this.initialize = bind(this.initialize, this);
      return Asset.__super__.constructor.apply(this, arguments);
    }

    Asset.prototype.defaultSize = "full";

    Asset.prototype.tagName = "figure";

    Asset.prototype.className = "ed-embed";

    Asset.prototype.editorView = "AssetEditor";

    Asset.prototype.ui = {
      holder: ".holder",
      overlay: ".darken",
      prompt: ".prompt"
    };

    Asset.prototype.initialize = function() {
      Asset.__super__.initialize.apply(this, arguments);
      return this._size != null ? this._size : this._size = _.result(this, 'defaultSize');
    };

    Asset.prototype.onRender = function() {
      this.$el.attr("contenteditable", false);
      if (this.model) {
        this.stickit();
      }
      return this.addEditor();
    };

    Asset.prototype.addEditor = function() {
      var editor_view_class;
      if (editor_view_class = Ed.Views[this.getOption('editorView')]) {
        this._editor = new editor_view_class({
          model: this.model
        });
        this._editor.$el.appendTo(this.el);
        this._editor.render();
        this._editor.on('remove', this.remove);
        this._editor.on('update', this.update);
        return this._editor.on('select', this.setModel);
      }
    };

    Asset.prototype.update = function() {
      var content_parent;
      content_parent = this.$el.parent('[contenteditable]');
      this.log("🦋 update", content_parent);
      return content_parent.trigger('input');
    };

    Asset.prototype.remove = function() {
      return this.$el.slideUp('fast', (function(_this) {
        return function() {
          var p;
          _this.update();
          p = $("<p />").insertBefore(_this.$el);
          _this.$el.remove();
          return p.focus();
        };
      })(this));
    };

    Asset.prototype.setModel = function(model) {
      this.model = model;
      if (this.model) {
        this.stickit();
      }
      return this.update();
    };

    return Asset;

  })(Ed.WrappedView);

  Ed.Views.Image = (function(superClass) {
    extend(Image, superClass);

    function Image() {
      this.onRender = bind(this.onRender, this);
      this.wrap = bind(this.wrap, this);
      return Image.__super__.constructor.apply(this, arguments);
    }

    Image.prototype.editorView = "ImageEditor";

    Image.prototype.template = "ed/image";

    Image.prototype.className = "image full ed-embed";

    Image.prototype.defaultSize = "full";

    Image.prototype.bindings = {
      ":el": {
        attributes: [
          {
            name: "data-image",
            observe: "id"
          }
        ]
      },
      "img": {
        attributes: [
          {
            name: "src",
            observe: ["url", "file_data"],
            onGet: "thisOrThat"
          }
        ]
      }
    };

    Image.prototype.wrap = function() {
      var image_id;
      if (image_id = this.$el.data('image')) {
        this.model = _ed.images.get(image_id);
        return this.triggerMethod('wrap');
      }
    };

    Image.prototype.onRender = function() {
      if (this.model == null) {
        this.model = new Ed.Models.Image;
      }
      return Image.__super__.onRender.apply(this, arguments);
    };

    return Image;

  })(Ed.Views.Asset);

  Ed.Views.MainImage = (function(superClass) {
    extend(MainImage, superClass);

    function MainImage() {
      this.bindImage = bind(this.bindImage, this);
      this.setModel = bind(this.setModel, this);
      this.wrap = bind(this.wrap, this);
      return MainImage.__super__.constructor.apply(this, arguments);
    }

    MainImage.prototype.editorView = "MainImageEditor";

    MainImage.prototype.template = _.noop;

    MainImage.prototype.defaultSize = "hero";

    MainImage.prototype.wrap = function() {
      var image_id;
      this.$el.addClass('editing');
      if (image_id = this.$el.data('image')) {
        this.setModel(_ed.images.get(image_id));
      } else {
        this.setModel(null);
      }
      return this.triggerMethod('wrap');
    };

    MainImage.prototype.setModel = function(image) {
      this.log("setModel", image);
      this.bindImage(image);
      return this.model.setImage(image);
    };

    MainImage.prototype.bindImage = function(image) {
      if (this.image) {
        this.unstickit(this.image);
      }
      if (image) {
        this.log("bindImage", image);
        this.ui.overlay.show();
        this.image = image;
        this.addBinding(this.image, ":el", {
          attributes: [
            {
              name: "style",
              observe: "url",
              onGet: "styleBackgroundAtSize"
            }
          ]
        });
      } else {
        this.log("unbindImage");
        this.ui.overlay.hide();
        this.$el.css({
          'background-image': ''
        });
      }
      return this.stickit();
    };

    return MainImage;

  })(Ed.Views.Asset);

  Ed.Views.Video = (function(superClass) {
    extend(Video, superClass);

    function Video() {
      this.videoId = bind(this.videoId, this);
      this.hideVideo = bind(this.hideVideo, this);
      this.unlessEmbedded = bind(this.unlessEmbedded, this);
      this.onRender = bind(this.onRender, this);
      this.wrap = bind(this.wrap, this);
      return Video.__super__.constructor.apply(this, arguments);
    }

    Video.prototype.editorView = "VideoEditor";

    Video.prototype.template = "ed/video";

    Video.prototype.className = "video full ed-embed";

    Video.prototype.defaultSize = "full";

    Video.prototype.bindings = {
      ":el": {
        attributes: [
          {
            name: "data-video",
            observe: "id"
          }
        ]
      },
      ".embed": {
        observe: "embed_code",
        updateMethod: "html"
      },
      "video": {
        observe: ["url", "embed_code"],
        visible: "thisButNotThat",
        attributes: [
          {
            name: "id",
            observe: "id",
            onGet: "videoId"
          }, {
            name: "poster",
            observe: "full_url"
          }
        ]
      },
      "img": {
        attributes: [
          {
            name: "src",
            observe: "full_url"
          }
        ]
      },
      "source": {
        attributes: [
          {
            name: "src",
            observe: "url"
          }
        ]
      }
    };

    Video.prototype.wrap = function() {
      var video_id;
      if (video_id = this.$el.data('video')) {
        this.model = _ed.videos.get(video_id);
        return this.triggerMethod('wrap');
      }
    };

    Video.prototype.onRender = function() {
      if (this.model == null) {
        this.model = new Ed.Models.Video;
      }
      return Video.__super__.onRender.apply(this, arguments);
    };

    Video.prototype.unlessEmbedded = function(embed_code) {
      return !embed_code;
    };

    Video.prototype.hideVideo = function(el, visible, model) {
      if (!visible) {
        return el.hide();
      }
    };

    Video.prototype.videoId = function(id) {
      return "video_" + id;
    };

    return Video;

  })(Ed.Views.Asset);

  Ed.Views.Block = (function(superClass) {
    extend(Block, superClass);

    function Block() {
      this.readHtml = bind(this.readHtml, this);
      this.removeBlock = bind(this.removeBlock, this);
      this.onRender = bind(this.onRender, this);
      return Block.__super__.constructor.apply(this, arguments);
    }

    Block.prototype.template = "ed/block";

    Block.prototype.className = "block";

    Block.prototype.ui = {
      buttons: ".ed-buttons",
      content: ".ed-block",
      remover: "a.remover"
    };

    Block.prototype.events = {
      "click a.remove": "removeBlock"
    };

    Block.prototype.bindings = {
      ":el": {
        observe: "content",
        updateMethod: "html",
        onGet: "readHtml"
      }
    };

    Block.prototype.onRender = function() {
      this.$el.attr('contenteditable', true);
      this.stickit();
      this._toolbar = new Ed.Views.Toolbar({
        target: this.ui.content
      });
      return this._toolbar.render();
    };

    Block.prototype.removeBlock = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      return this.$el.fadeOut((function(_this) {
        return function() {
          return _this.model.remove();
        };
      })(this));
    };

    Block.prototype.readHtml = function(html) {
      return html || "<p></p>";
    };

    return Block;

  })(Ed.View);

  Ed.Views.Blocks = (function(superClass) {
    extend(Blocks, superClass);

    function Blocks() {
      this.setLengthClass = bind(this.setLengthClass, this);
      this.addBlock = bind(this.addBlock, this);
      this.addEmptyBlock = bind(this.addEmptyBlock, this);
      this.onRender = bind(this.onRender, this);
      this.wrap = bind(this.wrap, this);
      return Blocks.__super__.constructor.apply(this, arguments);
    }

    Blocks.prototype.template = "ed/blockset";

    Blocks.prototype.tagName = "section";

    Blocks.prototype.className = "blockset";

    Blocks.prototype.childViewContainer = ".blocks";

    Blocks.prototype.childView = Ed.Views.Block;

    Blocks.prototype.ui = {
      buttons: ".ed-buttons",
      block_holder: ".blocks",
      blocks: ".block"
    };

    Blocks.prototype.events = {
      "click a.addblock": "addEmptyBlock"
    };

    Blocks.prototype.wrap = function() {
      this.collection = new Ed.Collections.Blocks;
      if (this.ui.blocks.length) {
        return this.ui.blocks.each((function(_this) {
          return function(i, block) {
            var $block;
            $block = $(block);
            _this.addBlock($block.html());
            return $block.remove();
          };
        })(this));
      } else {
        this.addBlock();
        this.addBlock();
        return this.addBlock();
      }
    };

    Blocks.prototype.onRender = function() {
      this.$el.attr("contenteditable", false);
      this.setLengthClass();
      return this.collection.on('add remove reset', this.setLengthClass);
    };

    Blocks.prototype.addEmptyBlock = function() {
      console.log("addEmptyBlock");
      return this.collection.add({
        content: ""
      });
    };

    Blocks.prototype.addBlock = function(content) {
      if (content == null) {
        content = "";
      }
      return this.collection.add({
        content: content
      });
    };

    Blocks.prototype.setLengthClass = function() {
      console.log("setLengthClass", this.collection.length);
      this.ui.block_holder.removeClass('none one two three four').addClass(['none', 'one', 'two', 'three', 'four'][this.collection.length]);
      if (this.collection.length >= 4) {
        return this.ui.buttons.addClass('inactive');
      } else {
        return this.ui.buttons.removeClass('inactive');
      }
    };

    return Blocks;

  })(Ed.CompositeView);

  Ed.Views.Quote = (function(superClass) {
    extend(Quote, superClass);

    function Quote() {
      this.classFromLength = bind(this.classFromLength, this);
      this.focus = bind(this.focus, this);
      this.wrap = bind(this.wrap, this);
      return Quote.__super__.constructor.apply(this, arguments);
    }

    Quote.prototype.editorView = "QuoteEditor";

    Quote.prototype.template = "ed/quote";

    Quote.prototype.className = "quote full ed-embed";

    Quote.prototype.defaultSize = "full";

    Quote.prototype.ui = {
      holder: ".holder",
      quote: "blockquote",
      caption: "figcaption"
    };

    Quote.prototype.bindings = {
      ":el": {
        attributes: [
          {
            name: "class",
            observe: "utterance",
            onGet: "classFromLength"
          }
        ]
      },
      "blockquote": {
        observe: "utterance"
      },
      "figcaption": {
        observe: "caption"
      }
    };

    Quote.prototype.wrap = function() {
      this.model = new Ed.Models.Quote({
        utterance: this.$el.find('blockquote').text(),
        caption: this.$el.find('figcaption').text()
      });
      return this.log("🚜 wrapped quote", this.el, _.clone(this.model.attributes));
    };

    Quote.prototype.focus = function() {
      return this.ui.quote.focus();
    };

    Quote.prototype.classFromLength = function(text) {
      var l;
      if (text == null) {
        text = "";
      }
      l = text.replace(/&nbsp;/g, ' ').trim().length;
      if (l < 28) {
        return "veryshort";
      } else if (l < 64) {
        return "short";
      } else if (l < 128) {
        return "shortish";
      } else {
        return "";
      }
    };

    return Quote;

  })(Ed.Views.Asset);

  Ed.Views.Button = (function(superClass) {
    extend(Button, superClass);

    function Button() {
      this.classFromLength = bind(this.classFromLength, this);
      this.focus = bind(this.focus, this);
      this.wrap = bind(this.wrap, this);
      return Button.__super__.constructor.apply(this, arguments);
    }

    Button.prototype.editorView = "ButtonEditor";

    Button.prototype.template = "ed/button";

    Button.prototype.tagName = "figure";

    Button.prototype.className = "button full";

    Button.prototype.defaultSize = "full";

    Button.prototype.ui = {
      buttons: ".ed-buttons",
      label: "span.label",
      url: "span.url"
    };

    Button.prototype.bindings = {
      ":el": {
        attributes: [
          {
            name: "class",
            observe: "label",
            onGet: "classFromLength"
          }, {
            name: "href",
            observe: "url"
          }
        ]
      },
      "span.label": {
        observe: "label"
      }
    };

    Button.prototype.wrap = function() {
      return this.model = new Ed.Models.Button({
        label: this.ui.label.text()
      });
    };

    Button.prototype.focus = function() {
      return this.ui.label.focus();
    };

    Button.prototype.classFromLength = function(text) {
      var l;
      if (text == null) {
        text = "";
      }
      l = text.replace(/&nbsp;/g, ' ').trim().length;
      if (l < 10) {
        return "veryshort";
      } else if (l < 20) {
        return "short";
      } else if (l < 40) {
        return "shortish";
      } else {
        return "";
      }
    };

    return Button;

  })(Ed.Views.Asset);

}).call(this);