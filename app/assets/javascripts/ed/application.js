(function() {
  var Ed, root,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Ed = {};

  Ed.version = '0.2.0';

  Ed.subtitle = "β";

  Ed.Models = {};

  Ed.Collections = {};

  Ed.Views = {};

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.Ed = Ed;

  Ed.Application = (function(superClass) {
    extend(Application, superClass);

    function Application() {
      this.stopLogging = bind(this.stopLogging, this);
      this.startLogging = bind(this.startLogging, this);
      this.logging = bind(this.logging, this);
      this.log = bind(this.log, this);
      this.notify = bind(this.notify, this);
      this.complain = bind(this.complain, this);
      this.confirm = bind(this.confirm, this);
      this.reportError = bind(this.reportError, this);
      this.sync = bind(this.sync, this);
      this.apiUrl = bind(this.apiUrl, this);
      this.getOption = bind(this.getOption, this);
      this.withAssets = bind(this.withAssets, this);
      this.loadAssets = bind(this.loadAssets, this);
      this.config = bind(this.config, this);
      this.reset = bind(this.reset, this);
      this.initUI = bind(this.initUI, this);
      this.region = bind(this.region, this);
      return Application.__super__.constructor.apply(this, arguments);
    }

    Application.prototype.defaults = {
      asset_styles: null
    };

    Application.prototype.initialize = function(opts) {
      if (opts == null) {
        opts = {};
      }
      root._ed = this;
      root.onerror = this.reportError;
      this.original_backbone_sync = Backbone.sync;
      Backbone.sync = this.sync;
      Marionette.setRenderer(this.render);
      this.options = _.extend(this.defaults, opts);
      this.el = this.options.el;
      this._loaded = $.Deferred();
      this._config = new Ed.Config(this.options.config);
      this.images = new Ed.Collections.Images;
      this.videos = new Ed.Collections.Videos;
      this.notices = new Ed.Collections.Notices;
      return this.initUI();
    };

    Application.prototype.region = function() {
      return this.el;
    };

    Application.prototype.initUI = function(fn) {
      this.model = new Ed.Models.Editable;
      return this.loadAssets().done((function(_this) {
        return function() {
          return _this._editor = new Ed.Views.Editor({
            model: _this.model,
            el: _this.el
          });
        };
      })(this));
    };

    Application.prototype.reset = function() {
      return this.initUI();
    };

    Application.prototype.config = function(key) {
      return this._config.get(key);
    };

    Application.prototype.loadAssets = function() {
      $.when(this.images.fetch(), this.videos.fetch()).done((function(_this) {
        return function() {
          return _this._loaded.resolve(_this.images, _this.videos);
        };
      })(this));
      return this._loaded.promise();
    };

    Application.prototype.withAssets = function(fn) {
      return this._loaded.done(fn);
    };

    Application.prototype.getOption = function(key) {
      return this.options[key];
    };

    Application.prototype.apiUrl = function(path) {
      var base_url;
      base_url = this.config('api_url');
      return [base_url, path].join('/');
    };

    Application.prototype.sync = function(method, model, opts) {
      var original_success;
      if (!(method === "read" || !model.startProgress)) {
        original_success = opts.success;
        opts.attrs = model.toJSON();
        model.startProgress("Saving");
        opts.beforeSend = function(xhr, settings) {
          return settings.xhr = function() {
            xhr = new window.XMLHttpRequest();
            xhr.upload.addEventListener("progress", function(e) {
              return model.setProgress(e);
            }, false);
            return xhr;
          };
        };
        opts.success = function(data, status, request) {
          model.finishProgress(true);
          model.clearTemporaryAttributes();
          return original_success(data, status, request);
        };
      }
      return this.original_backbone_sync(method, model, opts);
    };

    Application.prototype.render = function(template, data) {
      var jst_function;
      if (template != null) {
        if (jst_function = JST[template]) {
          return jst_function(data);
        } else if (_.isFunction(template)) {
          return template(data);
        } else {
          return template;
        }
      } else {
        return "";
      }
    };

    Application.prototype.reportError = function(message, source, lineno, colno, error) {
      var complaint;
      complaint = "<strong>" + message + "</strong> at " + source + " line " + lineno + " col " + colno + ".";
      if (this.config('display_errors')) {
        this.complain(complaint, 60000);
      }
      if (this.config('trap_errors')) {
        return true;
      }
    };

    Application.prototype.confirm = function(message, duration) {
      if (duration == null) {
        duration = 4000;
      }
      return this.notify(message, duration, 'confirmation');
    };

    Application.prototype.complain = function(message, duration) {
      if (duration == null) {
        duration = 20000;
      }
      return this.notify(message, duration, 'error');
    };

    Application.prototype.notify = function(html_or_text, duration, notice_type) {
      if (duration == null) {
        duration = 4000;
      }
      if (notice_type == null) {
        notice_type = 'information';
      }
      return this.notices.add({
        message: html_or_text,
        duration: duration,
        notice_type: notice_type
      });
    };

    Application.prototype.log = function() {
      if (((typeof console !== "undefined" && console !== null ? console.log : void 0) != null) && this.logging()) {
        return console.log.apply(console, arguments);
      }
    };

    Application.prototype.logging = function() {
      return this._logging || this.config('logging');
    };

    Application.prototype.startLogging = function() {
      return this._logging = true;
    };

    Application.prototype.stopLogging = function(level) {
      return this._logging = false;
    };

    return Application;

  })(Marionette.Application);

}).call(this);