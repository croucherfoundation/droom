(function() {
  var slice = [].slice;

  jQuery(function($) {
    $.zeroPad = function(n, width) {
      if (width == null) {
        width = 2;
      }
      n = n + '';
      while (n.length < width) {
        n = "0" + n;
      }
      return n;
    };
    $.makeGuid = function() {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r, v;
        r = Math.random() * 16 | 0;
        v = c === 'x' ? r : r & 0x3 | 0x8;
        return v.toString(16);
      });
    };
    $.urlParam = function(name, url) {
      var results;
      if (url == null) {
        url = window.location.href;
      }
      results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(url);
      if (!results) {
        return false;
      }
      return results[1] || null;
    };
    $.significantKeypress = function(kc) {
      return (kc === 13) || (kc === 8) || (kc === 46) || ((47 < kc && kc < 91)) || ((96 < kc && kc < 112)) || (kc > 145);
    };
    $.fn.sendCommand = function(command, args) {
      return this.each(function() {
        var payload;
        payload = JSON.stringify({
          "event": "command",
          "func": command,
          "args": args || [],
          "id": this.id
        });
        return this.contentWindow.postMessage(payload, "*");
      });
    };
    $.fn.trigger_change_on_deselect = function() {
      return this.each(function() {
        var input, name;
        input = $(this);
        name = input.attr('name');
        return $("input[name='" + name + "']:radio").not(input).change(function() {
          if ($(this).is(":checked")) {
            return input.change();
          }
        });
      });
    };
    $.easing.glide = function(x, t, b, c, d) {
      return -c * ((t = t / d - 1) * t * t * t - 1) + b;
    };
    $.easing.boing = function(x, t, b, c, d, s) {
      if (s == null) {
        s = 1.70158;
      }
      return c * ((t = t / d - 1) * t * ((s + 1) * t + s) + 1) + b;
    };
    $.easing.expo = function(x, t, b, c, d) {
      var ref;
      return (ref = t === d) != null ? ref : b + {
        c: c * (-Math.pow(2, -10 * t / d) + 1) + b
      };
    };
    $.add_stylesheet = function(path) {
      if (document.createStyleSheet) {
        return document.createStyleSheet(path);
      } else {
        return $('head').append("<link rel=\"stylesheet\" href=\"" + path + "\" type=\"text/css\" />");
      }
    };
    $.namespace = function(target, name, block) {
      var item, j, len, ref, ref1, top;
      if (arguments.length < 3) {
        ref = [(typeof exports !== 'undefined' ? exports : window)].concat(slice.call(arguments)), target = ref[0], name = ref[1], block = ref[2];
      }
      top = target;
      ref1 = name.split('.');
      for (j = 0, len = ref1.length; j < len; j++) {
        item = ref1[j];
        target = target[item] || (target[item] = {});
      }
      return block(target, top);
    };
    $.fn.find_including_self = function(selector) {
      var selection;
      selection = this.find(selector);
      if (this.is(selector)) {
        selection.push(this);
      }
      return selection;
    };
    $.fn.self_or_ancestor = function(selector) {
      if (this.is(selector)) {
        return this;
      } else {
        return this.parents(selector);
      }
    };
    $.ajaxError = (function(_this) {
      return function(jqXHR, textStatus, errorThrown) {
        console.log("...error!", jqXHR, textStatus, errorThrown);
        trigger("error", textStatus, errorThrown);
      };
    })(this);
    $.fn.flash = function() {
      return this.each(function() {
        var container;
        container = $(this);
        container.fadeIn("fast");
        $("<a href=\"#\" class=\"closer\">close</a>").prependTo(container);
        return container.bind("click", function(e) {
          e.preventDefault();
          return container.fadeOut("fast");
        });
      });
    };
    $.fn.disappearAfter = function(interval) {
      return $(this).fadeOut("slow", function() {
        return $(this).remove();
      });
    };
    $.fn.signal = function(color, duration) {
      var $el, fade_to;
      if (color == null) {
        color = "#f7f283";
      }
      $el = $(this);
      fade_to = $el.css('backgroundColor') || '#ffffff';
      if (fade_to === "rgba(0, 0, 0, 0)") {
        fade_to = "rgba(255, 255, 255, 0)";
      }
      console.log("fade_to", fade_to);
      if (duration == null) {
        duration = 1000;
      }
      return this.each(function() {
        return $(this).css('backgroundColor', color).animate({
          'backgroundColor': fade_to
        }, duration);
      });
    };
    $.fn.signal_confirmation = function() {
      return this.signal('#c7ebb4');
    };
    $.fn.signal_error = function() {
      return this.signal('#e55a51');
    };
    $.fn.signal_cancellation = function() {
      return this.signal('#a2a3a3');
    };
    $.fn.back_button = function() {
      return this.click(function(e) {
        if (e) {
          e.preventDefault();
        }
        history.back();
        return true;
      });
    };
    $.fn.disable = function() {
      return this.each(function() {
        return $(this).addClass('disabled').find('input, select, textarea').attr('disabled', true);
      });
    };
    $.fn.enable = function() {
      return this.each(function() {
        return $(this).removeClass('disabled').find('input, select, textarea').attr('disabled', false);
      });
    };
    $.activations = [];
    $.activate_with = function(fn) {
      return $.activations.push(fn);
    };
    return $.fn.activate = function() {
      console.log("base activate");
      $.each($.activations, (function(_this) {
        return function(i, fn) {
          return fn.apply(_this);
        };
      })(this));
      return this;
    };
  });

}).call(this);