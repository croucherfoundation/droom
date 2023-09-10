(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  Ed.View = (function(superClass) {
    extend(View, superClass);

    function View() {
      this.containEvent = bind(this.containEvent, this);
      this.isBlank = bind(this.isBlank, this);
      this.clearP = bind(this.clearP, this);
      this.ensureP = bind(this.ensureP, this);
      this.styleBackgroundAtSize = bind(this.styleBackgroundAtSize, this);
      this.urlAtSize = bind(this.urlAtSize, this);
      this.styleBackgroundImageAndPosition = bind(this.styleBackgroundImageAndPosition, this);
      this.styleBackgroundImage = bind(this.styleBackgroundImage, this);
      this.styleBackgroundColor = bind(this.styleBackgroundColor, this);
      this.styleColor = bind(this.styleColor, this);
      this.providerClass = bind(this.providerClass, this);
      this.asPercentage = bind(this.asPercentage, this);
      this.inTime = bind(this.inTime, this);
      this.inPixels = bind(this.inPixels, this);
      this.inBytes = bind(this.inBytes, this);
      this.present = bind(this.present, this);
      this.ifBlank = bind(this.ifBlank, this);
      this.thisButNotThat = bind(this.thisButNotThat, this);
      this.thisOrThat = bind(this.thisOrThat, this);
      this.untrue = bind(this.untrue, this);
      this.onDestroy = bind(this.onDestroy, this);
      this.onRender = bind(this.onRender, this);
      this.initialize = bind(this.initialize, this);
      return View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.template = _.noop;

    View.prototype.initialize = function() {
      return this.subviews = [];
    };

    View.prototype.onRender = function() {
      console.log("🦋 onRender", this.model);
      if (this.model) {
        return this.stickit();
      }
    };

    View.prototype.onDestroy = function() {
      var i, len, ref, results, subview;
      ref = this.subviews;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        subview = ref[i];
        results.push(subview.destroy());
      }
      return results;
    };

    View.prototype.untrue = function(value) {
      return !value;
    };

    View.prototype.thisOrThat = function(arg) {
      var other_thing, ref, thing;
      ref = arg != null ? arg : [], thing = ref[0], other_thing = ref[1];
      this.log("thisOrThat", thing, other_thing);
      return thing || other_thing || "";
    };

    View.prototype.thisButNotThat = function(arg) {
      var other_thing, ref, thing;
      ref = arg != null ? arg : [], thing = ref[0], other_thing = ref[1];
      this.log("thisButNotThat", thing, other_thing);
      return !!thing && !!!other_thing;
    };

    View.prototype.ifBlank = function(value) {
      return !(value != null ? value.trim() : void 0);
    };

    View.prototype.present = function(value) {
      return !!value;
    };

    View.prototype.inBytes = function(value) {
      var kb, mb;
      if (value) {
        if (value > 1048576) {
          mb = Math.floor(value / 10485.76) / 100;
          return mb + "MB";
        } else {
          kb = Math.floor(value / 1024);
          return kb + "KB";
        }
      } else {
        return "";
      }
    };

    View.prototype.inPixels = function(value) {
      if (value == null) {
        value = 0;
      }
      return value + "px";
    };

    View.prototype.inTime = function(value) {
      var minutes, seconds;
      if (value == null) {
        value = 0;
      }
      seconds = parseInt(value, 10);
      if (seconds >= 3600) {
        minutes = Math.floor(seconds / 60);
        return [Math.floor(minutes / 60), minutes % 60, seconds % 60].join(':');
      } else {
        return [Math.floor(seconds / 60), seconds % 60].join(':');
      }
    };

    View.prototype.asPercentage = function(value) {
      if (value == null) {
        value = 0;
      }
      return value + "%";
    };

    View.prototype.providerClass = function(provider) {
      if (provider === "YouTube") {
        return "yt";
      }
    };

    View.prototype.styleColor = function(color) {
      if (color) {
        return "color: " + color;
      }
    };

    View.prototype.styleBackgroundColor = function(color) {
      if (color) {
        return "background-color: " + color;
      }
    };

    View.prototype.styleBackgroundImage = function(arg) {
      var data, ref, url;
      ref = arg != null ? arg : [], url = ref[0], data = ref[1];
      debugger;
      url || (url = data);
      if (url) {
        return "background-image: url('" + url + "')";
      } else {
        return "";
      }
    };

    View.prototype.styleBackgroundImageAndPosition = function(arg) {
      var ref, url, weighting;
      ref = arg != null ? arg : [], url = ref[0], weighting = ref[1];
      if (weighting == null) {
        weighting = 'center center';
      }
      return "background-image: url('" + url + "'); background-position: " + weighting;
    };

    View.prototype.urlAtSize = function(url) {
      var ref;
      return (ref = this.model.get(this._size + "_url")) != null ? ref : url;
    };

    View.prototype.styleBackgroundAtSize = function(url) {
      if (url) {
        return "background-image: url('" + (this.urlAtSize(url)) + "')";
      }
    };

    View.prototype.ensureP = function(e) {
      var el, p;
      el = e.target;
      if (el.innerHTML === "") {
        el.style.minHeight = el.offsetHeight + 'px';
        p = document.createElement('p');
        p.innerHTML = "&#8203;";
        return el.appendChild(p);
      }
    };

    View.prototype.clearP = function(e) {
      var content, el;
      el = e.target;
      content = el.innerHTML;
      if (content === "<p>&#8203;</p>" || content === "<p><br></p>" || content === "<p></p>" || content === "<p>​</p>") {
        return el.innerHTML = "";
      }
    };

    View.prototype.isBlank = function(string) {
      if (string) {
        return /^\s*$/.test('' + string);
      } else {
        return true;
      }
    };

    View.prototype.containEvent = function(e) {
      if (e != null) {
        e.stopPropagation();
      }
      return e != null ? e.preventDefault() : void 0;
    };

    View.prototype.log = function() {
      return _ed.log.apply(_ed, ["[" + this.constructor.name + "]"].concat(slice.call(arguments)));
    };

    View.prototype.complain = function() {
      return _ed.complain.apply(_ed, arguments);
    };

    View.prototype.confirm = function() {
      return _ed.confirm.apply(_ed, arguments);
    };

    return View;

  })(Marionette.View);

  Ed.WrappedView = (function(superClass) {
    extend(WrappedView, superClass);

    function WrappedView() {
      this.beforeWrap = bind(this.beforeWrap, this);
      this.wrap = bind(this.wrap, this);
      this.initialize = bind(this.initialize, this);
      return WrappedView.__super__.constructor.apply(this, arguments);
    }

    WrappedView.prototype.template = _.noop;

    WrappedView.prototype.initialize = function() {
      this.subviews = [];
      this.beforeWrap();
      this.wrap();
      return this.render();
    };

    WrappedView.prototype.wrap = function() {
      return false;
    };

    WrappedView.prototype.beforeWrap = function() {
      return this.bindUIElements();
    };

    return WrappedView;

  })(Ed.View);

  Ed.CollectionView = (function(superClass) {
    extend(CollectionView, superClass);

    function CollectionView() {
      this.initialize = bind(this.initialize, this);
      return CollectionView.__super__.constructor.apply(this, arguments);
    }

    CollectionView.prototype.initialize = function() {
      return this.render();
    };

    CollectionView.prototype.log = function() {
      return _cms.log.apply(_cms, ["[" + this.constructor.name + "]"].concat(slice.call(arguments)));
    };

    return CollectionView;

  })(Marionette.CollectionView);

  Ed.CompositeView = (function(superClass) {
    extend(CompositeView, superClass);

    function CompositeView() {
      this.beforeWrap = bind(this.beforeWrap, this);
      this.wrap = bind(this.wrap, this);
      this.initialize = bind(this.initialize, this);
      return CompositeView.__super__.constructor.apply(this, arguments);
    }

    CompositeView.prototype.initialize = function() {
      this.beforeWrap();
      this.wrap();
      return this.render();
    };

    CompositeView.prototype.wrap = function() {};

    CompositeView.prototype.beforeWrap = function() {
      return this.bindUIElements();
    };

    return CompositeView;

  })(Marionette.CollectionView);

  Ed.Views.MenuView = (function(superClass) {
    extend(MenuView, superClass);

    function MenuView() {
      this.close = bind(this.close, this);
      this.open = bind(this.open, this);
      this.showing = bind(this.showing, this);
      this.toggleMenu = bind(this.toggleMenu, this);
      return MenuView.__super__.constructor.apply(this, arguments);
    }

    MenuView.prototype.ui = {
      head: ".menu-head",
      body: ".menu-body",
      closer: "a.close"
    };

    MenuView.prototype.events = {
      "click @ui.head": "toggleMenu",
      "click @ui.closer": "close"
    };

    MenuView.prototype.toggleMenu = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      if (this.showing()) {
        return this.close();
      } else {
        return this.open();
      }
    };

    MenuView.prototype.showing = function() {
      return this.$el.hasClass('open');
    };

    MenuView.prototype.open = function(e) {
      if (e != null) {
        e.preventDefault();
      }
      this.$el.addClass('open');
      this.triggerMethod('open');
      return this.trigger('opened');
    };

    MenuView.prototype.close = function(e) {
      var ref;
      if (e != null) {
        e.preventDefault();
      }
      if ((ref = this._menu_view) != null) {
        ref.close();
      }
      this.$el.removeClass('open');
      this.triggerMethod('close');
      return this.trigger('closed');
    };

    return MenuView;

  })(Ed.View);

}).call(this);