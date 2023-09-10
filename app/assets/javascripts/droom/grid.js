(function() {
  var Notice,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $.fn.autoGrid = function() {
    return this.each(function() {
      return $(this).find('.gridbox').gridBox();
    });
  };

  $.fn.gridBox = function() {
    return this.each(function() {
      var $el, row, sizer, space;
      $el = $(this);
      row = 20;
      space = 20;
      sizer = function() {
        var contents, rows_touched;
        contents = $el.find('.content');
        console.log("sizer!", contents, contents.outerHeight());
        rows_touched = Math.ceil(contents.outerHeight() / (row + space)) + 2;
        $el.css("grid-row-end", "span " + rows_touched);
        return $el.addClass('ready');
      };
      sizer();
      return $el.find('img').on('load', (function(_this) {
        return function() {
          console.log("resizer!");
          return sizer();
        };
      })(this));
    });
  };

  $.fn.highlight = function() {
    if (this.offset()) {
      $('html,body').animate({
        scrollTop: this.offset().top - 100
      }, 500);
      this.addClass('flash');
      return this.trigger('expand');
    }
  };

  $.fn.notice = function() {
    return this.each(function() {
      $(this).gridBox();
      return new Notice(this);
    });
  };

  Notice = (function() {
    function Notice(element) {
      this.refresh = bind(this.refresh, this);
      this.reflow = bind(this.reflow, this);
      this.toggleExpansion = bind(this.toggleExpansion, this);
      this.expand = bind(this.expand, this);
      this._container = $(element);
      this._container.gridBox();
      this._container.on('refreshed', this.refresh);
      this._expander = this._container.find('a.reveal');
      if (this._expander.length) {
        this._expander.bind('click', this.toggleExpansion);
      } else {
        this._container.addClass('unexpandable');
      }
      this._container.on('expand', this.expand);
    }

    Notice.prototype.expand = function() {
      this._container.addClass('expanded');
      return this.reflow();
    };

    Notice.prototype.toggleExpansion = function(e) {
      this._container.toggleClass('expanded');
      return this.reflow();
    };

    Notice.prototype.reflow = function() {
      return this._container.gridBox();
    };

    Notice.prototype.refresh = function(e, new_container) {
      this._container = $(new_container);
      this._container.on('refreshed', this.refresh);
      return this._expander = this._container.find('a.reveal');
    };

    return Notice;

  })();

}).call(this);