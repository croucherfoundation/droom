(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  jQuery(function($) {
    var Scrap, ScrapForm, Streamer;
    $.fn.add_to_stream = function() {
      if (this.length) {
        if ($.stream == null) {
          $.stream = new Streamer();
        }
        return $.stream.append(this);
      }
    };
    Streamer = (function() {
      function Streamer() {
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.resetSwipe = bind(this.resetSwipe, this);
        this.prev = bind(this.prev, this);
        this.next = bind(this.next, this);
        this.goto = bind(this.goto, this);
        this.refresh = bind(this.refresh, this);
        this.append = bind(this.append, this);
        this.containEvent = bind(this.containEvent, this);
        this.place = bind(this.place, this);
        this._container = $('<div class="streamer" />').appendTo($('body'));
        this._scroller = $('<div class="scroller" />').appendTo(this._container);
        $('<a class="next" href="#" />').appendTo(this._container).click(this.next);
        $('<a class="prev" href="#" />').appendTo(this._container).click(this.prev);
        $('<a class="closer" href="#" />').appendTo(this._container).click(this.hide);
        this._scraps = [];
        this._showing = false;
        this._modified = true;
        this.place();
        this._container.bind("mousedown", this.containEvent);
        this._container.bind("touchstart", this.containEvent);
        this._container.bind("refresh", this.refresh);
        $(window).bind("resize", this.place);
      }

      Streamer.prototype.place = function(e) {
        var w;
        w = $(window);
        return this._container.css({
          left: (w.width() - this._container.width()) / 2,
          top: (w.height() - this._container.height()) / 2
        });
      };

      Streamer.prototype.containEvent = function(e) {
        if (e) {
          return e.stopPropagation();
        }
      };

      Streamer.prototype.append = function(elements) {
        $(elements).each((function(_this) {
          return function(i, element) {
            var scrap;
            scrap = new Scrap(element, _this);
            scrap.container.removeClass('preload').appendTo(_this._scroller);
            return _this._scraps.push(scrap);
          };
        })(this));
        return this._modified = true;
      };

      Streamer.prototype.refresh = function(e) {};

      Streamer.prototype.goto = function(scrap) {
        return this._swipe.slide(this._scraps.indexOf(scrap));
      };

      Streamer.prototype.next = function() {
        return this._swipe.next();
      };

      Streamer.prototype.prev = function() {
        return this._swipe.prev();
      };

      Streamer.prototype.resetSwipe = function() {
        var ref;
        if ((ref = this._swipe) != null) {
          ref.kill();
        }
        this._swipe = new Swipe(this._container[0], {
          speed: 1000,
          auto: false,
          loop: false
        });
        $.swipe = this._swipe;
        return this._modified = false;
      };

      Streamer.prototype.show = function(scrap) {
        if (!this._showing) {
          this._container.fadeIn('fast', (function(_this) {
            return function() {
              if (_this._modified) {
                _this.resetSwipe();
              }
              if (scrap != null) {
                return _this.goto(scrap);
              }
            };
          })(this));
          this._showing = true;
          $(document).bind("mousedown", this.hide);
          return $(document).bind("touchstart", this.hide);
        }
      };

      Streamer.prototype.hide = function() {
        if (this._showing) {
          this._container.fadeOut('fast');
          $(document).unbind("mousedown", this.hide);
          $(document).unbind("touchstart", this.hide);
          return this._showing = false;
        }
      };

      return Streamer;

    })();
    Scrap = (function() {
      function Scrap(element, stream) {
        this.goto = bind(this.goto, this);
        this.container = $(element);
        this._stream = stream;
        $('a[data-scrap="' + this.container.attr('data-scrap') + '"]').click(this.goto);
      }

      Scrap.prototype.goto = function(e) {
        if (e) {
          e.preventDefault();
          e.stopPropagation();
        }
        return this._stream.show(this);
      };

      return Scrap;

    })();
    $.fn.scrap_form = function() {
      this.each(function() {
        return new ScrapForm(this);
      });
      return this;
    };
    return ScrapForm = (function() {
      function ScrapForm(element) {
        this.setType = bind(this.setType, this);
        this._container = $(element);
        this._header = this._container.find('.scraptypes');
        this._header.find('input:radio').change(this.setType);
        this.setType();
      }

      ScrapForm.prototype.setType = function() {
        var scraptype;
        scraptype = this._header.find('input:radio:checked').val();
        return this._container.attr("class", "scrap " + scraptype);
      };

      return ScrapForm;

    })();
  });

}).call(this);