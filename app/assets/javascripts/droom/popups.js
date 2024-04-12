(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  jQuery(function($) {
    var ActionMenu, Panel, Popup;
    $.fn.popup = function() {
      return this.each(function() {
        return new Popup(this);
      });
    };
    Popup = (function() {
      function Popup(element) {
        this.focus = bind(this.focus, this);
        this.place = bind(this.place, this);
        this.reset = bind(this.reset, this);
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.conclude = bind(this.conclude, this);
        this.display = bind(this.display, this);
        this.receive = bind(this.receive, this);
        this.prepare = bind(this.prepare, this);
        this.getContainer = bind(this.getContainer, this);
        this.begin = bind(this.begin, this);
        this._link = $(element);
        this._iteration = 0;
        this._affected = this._link.data('affected');
        this._replaced = this._link.data('replaced');
        this._removed = this._link.data('removed');
        this._aftered = this._link.data('appended');
        this._befored = this._link.data('prepended');
        this._reporter = this._link.data('reporter');
        this._style = this._link.data('style');
        this._delay = this._link.data('delay');
        this._masked = !this._link.data('unmasked');
        this._link.remote({
          on_request: this.begin,
          on_success: this.receive
        });
      }

      Popup.prototype.begin = function(event, xhr, settings) {
        switch (this._iteration) {
          case 0:
            return this.prepare();
          case 1:
            this.show();
            return false;
          default:
            this.reset();
            return this.prepare();
        }
      };

      Popup.prototype.getContainer = function() {
        var container;
        container = $('<div class="popup" />');
        if (this._style) {
          container.addClass(this._style);
        }
        return container;
      };

      Popup.prototype.prepare = function() {
        var body;
        body = $('body');
        if (this._masked) {
          this._mask = $('<div class="mask" />').appendTo(body);
        }
        if (this._container == null) {
          this._container = this.getContainer();
        }
        this._container.bind('close', this.reset);
        this._container.bind('finished', this.conclude);
        this._container.bind('resize', this.place);
        return this._container.appendTo(body).hide();
      };

      Popup.prototype.receive = function(e, data) {
        if (e != null) {
          e.stopPropagation();
        }
        if (this._iteration === 0 || $(data).find('form:not(#edit_cell)').not('.button_to').length) {
          return this.display(data);
        } else {
          return this.conclude(data);
        }
      };

      Popup.prototype.display = function(data) {
        this._iteration++;
        this._content = $(data);
        this._container.empty();
        this._container.append(this._content);
        this._content.activate();
        this.show();
        this._header = this._content.find('.header');
        this._content.find('form').remote({
          on_cancel: this.reset,
          on_success: this.receive
        });
        return this._content.find('a.popup ').remote({
          on_cancel: this.reset,
          on_success: this.receive
        });
      };

      Popup.prototype.conclude = function(data) {
        var addition, aff, replacement;
        if (this._affected) {
          aff = $(this._affected);
          if (this._delay) {
            _.delay(function() {
              return aff.trigger("refresh");
            }, this._delay);
          } else {
            aff.trigger("refresh");
          }
        }
        if (this._aftered != null) {
          addition = $(data);
          $(this._aftered).after(addition);
          addition.activate().signal_confirmation();
        }
        if (this._befored != null) {
          addition = $(data);
          $(this._befored).before(addition);
          addition.activate().signal_confirmation();
        }
        if (this._removed != null) {
          $(this._removed).remove();
        }
        if (this._replaced != null) {
          replacement = $(data);
          $(this._replaced).after(replacement);
          $(this._replaced).remove();
          replacement.activate().signal_confirmation();
        }
        if (this._reporter != null) {
          $(this._reporter).html(data).show().signal_confirmation().delay(5000).slideUp();
        }
        return this.reset();
      };

      Popup.prototype.show = function(e) {
        if (e) {
          e.preventDefault();
        }
        this.place();
        if (!this._container.is(":visible")) {
          this._container.fadeTo('fast', 1, (function(_this) {
            return function() {
              return _this._container.find('[autofocus]').focus();
            };
          })(this));
          if (this._masked) {
            this._mask.addClass('up');
            this._mask.bind("click", this.hide);
            $('#droom').addClass('masked');
          }
          $(window).bind("resize", this.place);
          return this.focus();
        }
      };

      Popup.prototype.hide = function(e) {
        if (e) {
          e.preventDefault();
        }
        this._container.fadeOut('fast');
        if (this._masked) {
          this._mask.removeClass('up');
          this._mask.unbind("click", this.hide);
          $('#droom').removeClass('masked');
        }
        return $(window).unbind("resize", this.place);
      };

      Popup.prototype.reset = function() {
        var ref;
        this.hide();
        this._container.remove();
        if ((ref = this._mask) != null) {
          ref.remove();
        }
        return this._iteration = 0;
      };

      Popup.prototype.place = function(e) {
        var height, height_limit, left, placement, pos, top, w, width;
        if ($('body').hasClass('mobile')) {
          return this._container.css({
            top: 0,
            left: 0
          });
        } else {
          width = this._container.children().first().width() || 580;
          w = $(window);
          height_limit = w.height() - 100;
          height = [this._container.height(), height_limit].min();
          if (pos = this._container.data('droom-positioned')) {
            placement = {
              left: pos.left + window.pageXOffset,
              top: pos.top + window.pageYOffset,
              width: width,
              "max-height": height_limit
            };
          } else {
            left = parseInt((w.width() - width) / 2) + window.pageXOffset;
            top = parseInt((w.height() - height - 40) / 2) + window.pageYOffset;
            placement = {
              left: left,
              top: top,
              width: width,
              "max-height": height_limit
            };
          }
          if (this._container.is(":visible")) {
            return this._container.animate(placement);
          } else {
            return this._container.css(placement);
          }
        }
      };

      Popup.prototype.focus = function() {
        return this._container.find('[autofocus]').focus();
      };

      return Popup;

    })();
    $.fn.action_menu = function() {
      this.each(function() {
        return new ActionMenu(this);
      });
      return this;
    };
    ActionMenu = (function() {
      ActionMenu.menus = $();

      ActionMenu.remember = function(menu) {
        return this.menus.push(menu);
      };

      ActionMenu.hideAll = function() {
        var i, len, menu, ref, results;
        ref = this.menus;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          menu = ref[i];
          results.push(menu.hide());
        }
        return results;
      };

      function ActionMenu(element) {
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.toggle = bind(this.toggle, this);
        this.place = bind(this.place, this);
        this._link = $(element);
        this._selector = "[data-for=\"" + (this._link.attr('data-menu')) + "\"]";
        this._link.click(this.toggle);
        ActionMenu.remember(this);
      }

      ActionMenu.prototype.place = function() {
        var pos;
        pos = this._link.position();
        return $(this._selector).css({
          top: pos.top + 20,
          left: pos.left
        });
      };

      ActionMenu.prototype.toggle = function(e) {
        if (e) {
          e.preventDefault();
          e.stopPropagation();
        }
        if (this._link.hasClass('up')) {
          return this.hide();
        } else {
          return this.show();
        }
      };

      ActionMenu.prototype.show = function(e) {
        this.place();
        ActionMenu.hideAll();
        this._link.addClass('up');
        $(this._selector).first().stop().slideDown('fast');
        return $(document).bind("click", this.hide);
      };

      ActionMenu.prototype.hide = function(e) {
        $(this._selector).first().stop().slideUp('fast', (function(_this) {
          return function() {
            return _this._link.removeClass('up');
          };
        })(this));
        return $(document).unbind("click", this.hide);
      };

      return ActionMenu;

    })();
    Panel = (function() {
      Panel.panels = $();

      Panel.remember = function(panel) {
        return this.panels.push(panel);
      };

      Panel.hideAll = function() {
        var i, len, panel, ref, results;
        ref = this.panels;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          panel = ref[i];
          results.push(panel.hide());
        }
        return results;
      };

      function Panel(element) {
        this.revert = bind(this.revert, this);
        this.show = bind(this.show, this);
        this.hideSoon = bind(this.hideSoon, this);
        this.hide = bind(this.hide, this);
        this.showOrGo = bind(this.showOrGo, this);
        this.toggle = bind(this.toggle, this);
        this.set = bind(this.set, this);
        this.setup = bind(this.setup, this);
        var box;
        console.log("panel", element);
        this.container = $(element);
        this.id = this.container.attr('data-panel');
        this.links = $("a[data-panel='" + this.id + "']");
        this.header = $("a[data-panel='" + this.id + "']");
        this.closer = this.container.find('a.close');
        box = this.header.offsetParent();
        this.container.appendTo(box);
        this.patch = $('<div class="patch" />').appendTo(box);
        this.timer = null;
        this.showing = false;
        this.links.bind("click", this.toggle);
        this.links.bind("touchstart", this.showOrGo);
        $(this.header).hover(this.show, this.hideSoon);
        $(this.patch).hover(this.show, this.hideSoon);
        $(this.container).hover(this.show, this.hideSoon);
        this.container.bind("show", this.show);
        this.container.bind("hide", this.hide);
        this.closer.bind("click", this.hide);
        this.set();
        Panel.remember(this);
      }

      Panel.prototype.setup = function() {
        var offset, position, top;
        if (!$('body').hasClass('mobile')) {
          position = this.header.position();
          offset = this.header.offset();
          top = position.top + this.header.outerHeight();
          this.patch.css({
            left: position.left + 1,
            top: top - 3,
            width: this.header.outerWidth() - 2
          });
          return this.container.css({
            right: 0,
            top: top - 1
          });
        }
      };

      Panel.prototype.set = function() {
        if (this.header.hasClass('here')) {
          return this.show();
        } else {
          return this.hide();
        }
      };

      Panel.prototype.toggle = function(e) {
        if (e) {
          e.preventDefault();
          e.stopPropagation();
        }
        if (this.showing) {
          return this.hide();
        } else {
          return this.show();
        }
      };

      Panel.prototype.showOrGo = function(e) {
        if (!this.showing) {
          if (e) {
            e.preventDefault();
            e.stopPropagation();
          }
          return this.show();
        }
      };

      Panel.prototype.hide = function(e) {
        window.clearTimeout(this.timer);
        this.container.removeClass('up');
        this.patch.removeClass('up');
        this.header.removeClass('up');
        return this.showing = false;
      };

      Panel.prototype.hideSoon = function() {
        return this.timer = window.setTimeout(this.hide, 500);
      };

      Panel.prototype.show = function(e) {
        var ref;
        window.clearTimeout(this.timer);
        if (!this.showing) {
          this.setup();
          Panel.hideAll();
          this.container.addClass('up');
          this.patch.addClass('up');
          this.header.addClass('up');
          this.showing = true;
          return (ref = this.container.find('input[autofocus]').get(0)) != null ? ref.focus() : void 0;
        }
      };

      Panel.prototype.revert = function(e) {
        return Panel.hideAll();
      };

      return Panel;

    })();
    return $.fn.panel = function() {
      this.each(function() {
        return new Panel(this);
      });
      return this;
    };
  });

}).call(this);