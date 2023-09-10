(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Ed.Config = (function() {
    Config.prototype.defaults = {
      api_url: "/api",
      logging: false,
      trap_errors: true,
      display_errors: false,
      badger_errors: true,
      insertions: ["image", "video", "quote", "button"]
    };

    Config.prototype.production = {
      display_errors: false,
      badger_errors: true,
      logging: false
    };

    Config.prototype.staging = {
      display_errors: true,
      badger_errors: true,
      trap_errors: false
    };

    Config.prototype.development = {
      logging: true,
      display_errors: true,
      badger_errors: false,
      trap_errors: false
    };

    function Config(options) {
      if (options == null) {
        options = {};
      }
      this.get = bind(this.get, this);
      this.settings = bind(this.settings, this);
      if (options.environment == null) {
        options.environment = this.guessEnvironment();
      }
      this._settings = _.defaults(options, this[options.environment], this.defaults);
    }

    Config.prototype.guessEnvironment = function() {
      var dev, href, stag;
      stag = new RegExp(/staging/);
      dev = new RegExp(/\.dev/);
      href = window.location.href;
      if (stag.test(href)) {
        return "staging";
      } else if (dev.test(href)) {
        return "development";
      } else {
        return "production";
      }
    };

    Config.prototype.settings = function() {
      return this._settings;
    };

    Config.prototype.get = function(key) {
      return this._settings[key];
    };

    return Config;

  })();

}).call(this);