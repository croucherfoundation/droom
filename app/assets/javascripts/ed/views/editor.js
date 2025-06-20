(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Ed.Views.Editor = (function(superClass) {
    extend(Editor, superClass);

    function Editor() {
      this.disableWhenBusy = bind(this.disableWhenBusy, this);
      this.cleanContent = bind(this.cleanContent, this);
      this.placeCaret = bind(this.placeCaret, this);
      this.onRender = bind(this.onRender, this);
      this.wrap = bind(this.wrap, this);
      return Editor.__super__.constructor.apply(this, arguments);
    }

    Editor.prototype.ui = {
      title: ".ed-title",
      subtitle: ".ed-subtitle",
      intro: ".ed-intro",
      slug: ".ed-slug",
      content: ".ed-content",
      image: ".ed-image",
      image_caption: ".ed-imagecaption",
      checkers: '[data-ed-check]',
      helpers: '.ed-help',
      notices: '#notices'
    };

    Editor.prototype.bindings = {
      '[data-ed="title"]': {
        observe: "title",
        updateModel: false
      },
      '[data-ed="subtitle"]': {
        observe: "subtitle",
        updateModel: false
      },
      '[data-ed="intro"]': {
        observe: "intro",
        updateModel: false
      },
      '[data-ed="slug"]': {
        observe: "slug",
        updateModel: false
      },
      '[data-ed="main_image_id"]': {
        observe: "main_image_id",
        updateModel: false
      },
      '[data-ed="main_image_weighting"]': {
        observe: "main_image_weighting",
        updateModel: false
      },
      '[data-ed="main_image_caption"]': {
        observe: "main_image_caption",
        updateModel: false
      },
      '[data-ed="content"]': {
        observe: "content",
        onGet: "cleanContent",
        updateModel: false
      },
      '[data-ed="submit"]': {
        observe: "busy",
        update: "disableWhenBusy"
      }
    };

    Editor.prototype.wrap = function() {
      this.ui.title.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Title({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.subtitle.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Subtitle({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.intro.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Intro({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.slug.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Slug({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.content.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Content({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.image.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.MainImage({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.image_caption.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.ImageCaption({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      this.ui.checkers.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Checker({
            el: el,
            model: _this.model
          }));
        };
      })(this));
      return this.ui.helpers.each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Helper({
            el: el,
            model: _this.model
          }));
        };
      })(this));
    };

    Editor.prototype.onRender = function() {
      var notices;
      this.stickit();
      this.placeCaret();
      notices = new Ed.Views.Notices({
        collection: _ed.notices,
        model: this.model
      });
      return notices.$el.appendTo(this.ui.notices);
    };

    Editor.prototype.placeCaret = function() {
      var range, selection, title_el;
      if (title_el = this.ui.title.get(0)) {
        range = document.createRange();
        range.setStart(title_el, 0);
        range.collapse(true);
        selection = window.getSelection();
        selection.removeAllRanges();
        return selection.addRange(range);
      }
    };

    Editor.prototype.cleanContent = function(content, model) {
      return this.model.cleanContent();
    };

    Editor.prototype.disableWhenBusy = function($el, busy, model, options) {
      if (busy) {
        return $el.disable();
      } else {
        return $el.enable();
      }
    };

    return Editor;

  })(Ed.WrappedView);

  Ed.Views.Title = (function(superClass) {
    extend(Title, superClass);

    function Title() {
      this.wrap = bind(this.wrap, this);
      return Title.__super__.constructor.apply(this, arguments);
    }

    Title.prototype.template = _.noop;

    Title.prototype.bindings = {
      ':el': {
        observe: 'title'
      }
    };

    Title.prototype.wrap = function() {
      return this.model.set('title', this.$el.text().trim());
    };

    return Title;

  })(Ed.WrappedView);

  Ed.Views.Subtitle = (function(superClass) {
    extend(Subtitle, superClass);

    function Subtitle() {
      this.wrap = bind(this.wrap, this);
      return Subtitle.__super__.constructor.apply(this, arguments);
    }

    Subtitle.prototype.template = _.noop;

    Subtitle.prototype.bindings = {
      ':el': {
        observe: 'subtitle'
      }
    };

    Subtitle.prototype.wrap = function() {
      return this.model.set('subtitle', this.$el.text().trim());
    };

    return Subtitle;

  })(Ed.WrappedView);

  Ed.Views.Slug = (function(superClass) {
    extend(Slug, superClass);

    function Slug() {
      this.wrap = bind(this.wrap, this);
      return Slug.__super__.constructor.apply(this, arguments);
    }

    Slug.prototype.template = _.noop;

    Slug.prototype.bindings = {
      ':el': {
        observe: 'slug'
      }
    };

    Slug.prototype.wrap = function() {
      return this.model.set('slug', this.$el.text().trim());
    };

    return Slug;

  })(Ed.WrappedView);

  Ed.Views.Intro = (function(superClass) {
    extend(Intro, superClass);

    function Intro() {
      this.wrap = bind(this.wrap, this);
      return Intro.__super__.constructor.apply(this, arguments);
    }

    Intro.prototype.template = _.noop;

    Intro.prototype.bindings = {
      ':el': {
        observe: 'intro'
      }
    };

    Intro.prototype.wrap = function() {
      return this.model.set('intro', this.$el.text().trim());
    };

    return Intro;

  })(Ed.WrappedView);

  Ed.Views.ImageCaption = (function(superClass) {
    extend(ImageCaption, superClass);

    function ImageCaption() {
      this.wrap = bind(this.wrap, this);
      return ImageCaption.__super__.constructor.apply(this, arguments);
    }

    ImageCaption.prototype.template = _.noop;

    ImageCaption.prototype.bindings = {
      ':el': {
        observe: 'main_image_caption'
      }
    };

    ImageCaption.prototype.wrap = function() {
      return this.model.set('main_image_caption', this.$el.text().trim());
    };

    return ImageCaption;

  })(Ed.WrappedView);

  Ed.Views.Content = (function(superClass) {
    extend(Content, superClass);

    function Content() {
      this.clearP = bind(this.clearP, this);
      this.ensureP = bind(this.ensureP, this);
      this.onRender = bind(this.onRender, this);
      this.dontShowPlaceholder = bind(this.dontShowPlaceholder, this);
      this.showPlaceholderSoon = bind(this.showPlaceholderSoon, this);
      this.showPlaceholder = bind(this.showPlaceholder, this);
      this.hidePlaceholder = bind(this.hidePlaceholder, this);
      this.showPlaceholderIfEmpty = bind(this.showPlaceholderIfEmpty, this);
      this.wrap = bind(this.wrap, this);
      return Content.__super__.constructor.apply(this, arguments);
    }

    Content.prototype.template = _.noop;

    Content.prototype.ui = {
      content: ".content",
      placeholder: ".placeholder"
    };

    Content.prototype.bindings = {
      '.content': {
        observe: 'content',
        updateView: false
      }
    };

    Content.prototype.wrap = function() {
      var content;
      content = this.ui.content.html().trim();
      this.model.set('content', content, {
        silent: true
      });
      this.showPlaceholderIfEmpty();
      this.ui.content.on('blur', this.showPlaceholderIfEmpty);
      this.ui.content.addClass('editing');
      this.ui.content.find('section.blockset').each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Blocks({
            el: el
          }));
        };
      })(this));
      this.ui.content.find('figure.image').each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Image({
            el: el
          }));
        };
      })(this));
      this.ui.content.find('figure.video').each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Video({
            el: el
          }));
        };
      })(this));
      this.ui.content.find('figure.quote').each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Quote({
            el: el
          }));
        };
      })(this));
      this.ui.content.find('figure.button').each((function(_this) {
        return function(i, el) {
          return _this.subviews.push(new Ed.Views.Button({
            el: el
          }));
        };
      })(this));
      this.ui.content.on('focus', this.ensureP).on('blur', this.clearP);
      return this.ui.placeholder.click((function(_this) {
        return function() {
          _this.ui.placeholder.hide();
          return _this.ui.content.show().focus();
        };
      })(this));
    };

    Content.prototype.showPlaceholderIfEmpty = function() {
      if (this.ui.content.text().trim()) {
        return this.hidePlaceholder();
      } else {
        return this.showPlaceholderSoon();
      }
    };

    Content.prototype.hidePlaceholder = function() {
      this.ui.placeholder.hide();
      return this.ui.content.show();
    };

    Content.prototype.showPlaceholder = function() {
      var ref;
      this.ui.content.hide();
      if ((ref = this._inserter) != null) {
        ref.hide();
      }
      return this.ui.placeholder.show();
    };

    Content.prototype.showPlaceholderSoon = function() {
      this.dontShowPlaceholder();
      return this._placeholdershower = window.setTimeout(this.showPlaceholder, 500);
    };

    Content.prototype.dontShowPlaceholder = function() {
      if (this._placeholdershower) {
        return window.clearTimeout(this._placeholdershower);
      }
    };

    Content.prototype.onRender = function() {
      this.stickit();
      this._inserter = new Ed.Views.AssetInserter;
      this._inserter.render();
      this._inserter.attendTo(this.ui.content);
      this._inserter.on('expand', this.dontShowPlaceholder);
      this.ui.content.on("focus", this.ensureP);
      return this.ui.content.on("blur", this.removeEmptyP);
    };

    Content.prototype.ensureP = function(e) {
      var el, p;
      el = e.target;
      if (el.innerHTML.trim() === "") {
        el.style.minHeight = el.offsetHeight + 'px';
        p = document.createElement('p');
        p.innerHTML = "&#8203;";
        return el.appendChild(p);
      }
    };

    Content.prototype.clearP = function(e) {
      var content, el;
      el = e.target;
      content = el.innerHTML;
      if (content === "<p>&#8203;</p>" || content === "<p><br></p>" || content === "<p>​</p>") {
        return el.innerHTML = "";
      }
    };

    return Content;

  })(Ed.WrappedView);

  Ed.Views.Checker = (function(superClass) {
    extend(Checker, superClass);

    function Checker() {
      this.checkSymbol = bind(this.checkSymbol, this);
      this.attributePresent = bind(this.attributePresent, this);
      this.wrap = bind(this.wrap, this);
      return Checker.__super__.constructor.apply(this, arguments);
    }

    Checker.prototype.template = _.noop;

    Checker.prototype.ui = {
      counter: 'span.count'
    };

    Checker.prototype.wrap = function() {
      this.attribute = this.$el.data('ed-check');
      this.addBinding(null, ':el', {
        observe: this.attribute,
        update: "attributePresent"
      });
      return this.addBinding(null, 'use.check', {
        attributes: [
          {
            name: "xlink:href",
            observe: this.attribute,
            onGet: "checkSymbol"
          }
        ]
      });
    };

    Checker.prototype.attributePresent = function($el, value, model, options) {
      var present, word_count, word_word, words;
      present = false;
      if (this.attribute === 'content') {
        value = this.model.textContent();
        if (value.trim() === "") {
          word_count = 0;
          this.ui.counter.text('');
        } else {
          words = _.filter(value.split(/\W+/), function(w) {
            return !!w.trim();
          });
          word_count = words.length;
          word_word = word_count === 1 ? " word" : " words";
          this.ui.counter.text("(You have " + word_count + " " + word_word + ")");
        }
        present = word_count > 20;
      } else {
        present = value;
      }
      if (present) {
        return $el.removeClass('missing').addClass('present');
      } else {
        return $el.removeClass('present').addClass('missing');
      }
    };

    Checker.prototype.checkSymbol = function(value) {
      if (value) {
        return "#tick_symbol";
      } else {
        return "#cross_symbol";
      }
    };

    return Checker;

  })(Ed.WrappedView);

  Ed.Views.Notice = (function(superClass) {
    extend(Notice, superClass);

    function Notice() {
      this.ifConfirmation = bind(this.ifConfirmation, this);
      this.ifError = bind(this.ifError, this);
      this.close = bind(this.close, this);
      this.fadeOut = bind(this.fadeOut, this);
      this.onRender = bind(this.onRender, this);
      return Notice.__super__.constructor.apply(this, arguments);
    }

    Notice.prototype.template = "ed/notice";

    Notice.prototype.tagName = "li";

    Notice.prototype.events = {
      "click": "fadeOut"
    };

    Notice.prototype.bindings = {
      ".message": {
        observe: "message",
        updateMethod: "html"
      },
      ":el": {
        attributes: [
          {
            name: "class",
            observe: "notice_type"
          }
        ]
      }
    };

    Notice.prototype.onRender = function() {
      var ref;
      this.stickit();
      return _.delay(this.fadeOut, (ref = this.model.get('duration')) != null ? ref : 4000);
    };

    Notice.prototype.fadeOut = function(duration) {
      if (duration == null) {
        duration = 500;
      }
      return this.$el.fadeOut(duration, this.close);
    };

    Notice.prototype.close = function(e) {
      this.$el.stop(true, false).hide();
      return this.model.discard();
    };

    Notice.prototype.ifError = function(value) {
      return value === 'error';
    };

    Notice.prototype.ifConfirmation = function(value) {
      return value === 'confirmation';
    };

    return Notice;

  })(Ed.View);

  Ed.Views.Notices = (function(superClass) {
    extend(Notices, superClass);

    function Notices() {
      return Notices.__super__.constructor.apply(this, arguments);
    }

    Notices.prototype.childView = Ed.Views.Notice;

    Notices.prototype.tagName = "ul";

    Notices.prototype.className = "notices";

    return Notices;

  })(Ed.CollectionView);

}).call(this);