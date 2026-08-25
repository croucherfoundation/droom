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
    $.fn.toast = function() {
      return this.each(function() {
        var container, hideToast, toast;
        container = $(this);
        toast = container.find('.croucher-toast');
        if (!toast.length) {
          return;
        }
        hideToast = function() {
          toast.removeClass('croucher-toast--show').addClass('croucher-toast--hide');
        };
        container.find('.croucher-toast__close').off('click.toast').on('click.toast', function(e) {
          e.preventDefault();
          return hideToast();
        });
        if (toast.hasClass('croucher-toast--show')) {
          clearTimeout(this._toastTimer);
          this._toastTimer = setTimeout(hideToast, 5000);
        }
      });
    };
    $.show_dataroom_toast = function(message, type, options) {
      var closeButton, container, content, hideToast, icon, iconUse, isSuccess, toast;
      options = options || {};
      container = $('.croucher-toast-container[data-remote-toast="true"]').first();
      if (!container.length) {
        return false;
      }
      toast = container.find('.croucher-toast').first();
      content = container.find('.croucher-toast__content').first();
      icon = container.find('.croucher-toast__icon').first();
      iconUse = icon.find('use').first();
      closeButton = container.find('.croucher-toast__close').first();
      if (!toast.length || !content.length || !icon.length || !iconUse.length) {
        return false;
      }
      isSuccess = type === 'notice';
      toast.removeClass('croucher-toast--hide').addClass('croucher-toast--show');
      icon.removeClass('croucher-toast__icon--success croucher-toast__icon--error').addClass(isSuccess ? 'croucher-toast__icon--success' : 'croucher-toast__icon--error');
      iconUse.attr('href', isSuccess ? '#confirmed_symbol' : '#warning_symbol');
      content.text(message);
      hideToast = function() {
        toast.removeClass('croucher-toast--show').addClass('croucher-toast--hide');
      };
      closeButton.off('click.toast').on('click.toast', function(e) {
        e.preventDefault();
        return hideToast();
      });
      clearTimeout(container[0]._toastTimer);
      if (options.persistent) {
        container[0]._toastTimer = null;
      } else {
        container[0]._toastTimer = setTimeout(hideToast, 5000);
      }
      return true;
    };
    $.fn.confirm_dialog = function(message, options) {
      var $scope;
      $scope = this;
      options = options || {};
      return new Promise(function(resolve) {
        var $cancel, $message, $ok, $overlay, hideDialog, method, okLabel, onCancel, onKeydown, onOk, previousResolver;
        $overlay = $scope.find('#confirm-overlay').first();
        if (!$overlay.length) {
          $overlay = $('#confirm-overlay').first();
        }
        if (!$overlay.length) {
          $overlay = $scope.find('.croucher-toast--confirmation').first();
        }
        if (!$overlay.length) {
          $overlay = $('.croucher-toast--confirmation').first();
        }
        $message = $overlay.find('#confirm-message').first();
        if (!$message.length) {
          $message = $overlay.find('.croucher-toast__content > span').first();
        }
        $ok = $overlay.find('#confirm-ok, .croucher-toast__btn-ok').first();
        $cancel = $overlay.find('#confirm-cancel, .croucher-toast__btn-cancel').first();
        if (!$overlay.length || !$message.length || !$ok.length || !$cancel.length) {
          resolve(window.confirm(message));
          return;
        }
        previousResolver = $overlay.data('confirmDialogResolver');
        if (typeof previousResolver === 'function') {
          previousResolver(false);
        }
        method = (options.method || '').toString().toLowerCase();
        okLabel = method === 'delete' ? 'Delete' : 'OK';
        if ($ok.is('input, textarea')) {
          $ok.val(okLabel);
        } else {
          $ok.text(okLabel);
        }
        $message.text(message);
        $overlay.removeClass('hidden croucher-toast--hide').addClass('croucher-toast--show');
        hideDialog = function(result) {
          $overlay.addClass('hidden croucher-toast--hide').removeClass('croucher-toast--show');
          $ok.off('click.confirm_dialog');
          $cancel.off('click.confirm_dialog');
          $(document).off('keydown.confirm_dialog');
          $overlay.removeData('confirmDialogResolver');
          resolve(!!result);
        };
        onOk = function(e) {
          if (e != null) {
            e.preventDefault();
          }
          return hideDialog(true);
        };
        onCancel = function(e) {
          if (e != null) {
            e.preventDefault();
          }
          return hideDialog(false);
        };
        onKeydown = function(e) {
          if (e.key === 'Escape') {
            return onCancel(e);
          }
          if (e.key === 'Enter') {
            return onOk(e);
          }
        };
        $overlay.data('confirmDialogResolver', hideDialog);
        $ok.off('click.confirm_dialog').on('click.confirm_dialog', onOk);
        $cancel.off('click.confirm_dialog').on('click.confirm_dialog', onCancel);
        $(document).off('keydown.confirm_dialog').on('keydown.confirm_dialog', onKeydown);
      });
    };
    $.install_confirm_dialog = function() {
      if (typeof $.rails === 'undefined') {
        console.warn("Rails UJS is not loaded. Confirm dialog will not be installed.");
        return false;
      }
      if (typeof $.rails.allowAction !== 'function') {
        console.warn("Rails UJS does not have allowAction function. Confirm dialog will not be installed.");
        return false;
      }
      if (typeof $.rails.fire !== 'function') {
        console.warn("Rails UJS does not have fire function. Confirm dialog will not be installed.");
        return false;
      }
      if (typeof $.rails._confirmDialogInstalled !== 'undefined') {
        console.warn("Confirm dialog is already installed.");
        return false;
      }
      var rails;
      rails = $.rails;
      if (!rails || rails._confirmDialogInstalled) {
        return false;
      }
      rails._confirmDialogInstalled = true;
      rails.allowAction = function(element) {
        var $element, callback, message, method;
        $element = $(element);
        message = $element.data('confirm');
        if (!message) {
          return true;
        }
        if ($element.data('ujs:confirmed')) {
          $element.removeData('ujs:confirmed');
          return true;
        }
        if (!rails.fire($element, 'confirm')) {
          return false;
        }
        method = $element.attr('data-method') || $element.data('method') || $element.attr('formmethod') || ($element.prop('formMethod') || '') || $element.attr('method') || $element.closest('form').find('input[name="_method"]').val() || $element.find('input[name="_method"]').val() || '';
        callback = true;
        $('body').confirm_dialog(message, {
          method: method.toString().toLowerCase()
        }).then(function(answer) {
          callback = rails.fire($element, 'confirm:complete', [answer]);
          if (!answer || callback === false) {
            return;
          }
          $element.data('ujs:confirmed', true);
          if ($element.is('form')) {
            return $element.trigger('submit.rails');
          }
          return $element.trigger('click.rails');
        });
        return false;
      };
      return true;
    };
    $.install_confirm_dialog();
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
    $.fn.custom_validation = function(rules) {
      return this.each(function() {
        var $form = $(this);
        if (rules) {
          $.each(rules, function(selector, message) {
            $form.find(selector).each(function() {
              var input = this;
              input.addEventListener('invalid', function() {
                if (input.validity.valueMissing || input.validity.tooShort) {
                  input.setCustomValidity(message);
                }
              });
              input.addEventListener('input', function() {
                input.setCustomValidity('');
              });
            });
          });
        } else {
          $form.find('[data-validation-message]').each(function() {
            var input = this;
            var message = $(input).data('validation-message');
            input.addEventListener('invalid', function() {
              if (input.validity.valueMissing || input.validity.tooShort) {
                input.setCustomValidity(message);
              }
            });
            input.addEventListener('input', function() {
              input.setCustomValidity('');
            });
          });
        }
      });
    };
    $.fn.password_toggle = function() {
      return this.each(function() {
        var $btn = $(this);
        var $input = $btn.siblings('input[type="password"], input[type="text"]');
        if (!$input.length) return;
        $btn.on('click', function() {
          var isPassword = $input.attr('type') === 'password';
          $input.attr('type', isPassword ? 'text' : 'password');
          var $img = $btn.find('img');
          if ($img.length) {
            var src = $img.attr('src');
            $img.attr('src', isPassword ? src.replace('eye-02.svg', 'eye-01.svg') : src.replace('eye-01.svg', 'eye-02.svg'));
            $img.attr('alt', isPassword ? 'hide' : 'show');
          }
        });
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