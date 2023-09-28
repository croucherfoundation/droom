(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  jQuery(function($) {
    var Alternator, Collapser, Filter, Refresher, Revealer, Search, Setter, Toggle;
    $.fn.refresher = function() {
      return this.each(function() {
        return new Refresher(this);
      });
    };
    $.fn.refresh = function() {
      return this.trigger('refresh');
    };
    Refresher = (function() {
      function Refresher(element) {
        this.replace = bind(this.replace, this);
        this.prep = bind(this.prep, this);
        this.refresh = bind(this.refresh, this);
        this._container = $(element);
        this._url = this._container.attr('data-refreshing') || this._container.attr('data-url');
        this._method = this._container.attr('data-method');
        this._data = this._container.attr('data-params');
        this._container.bind("refresh", this.refresh);
      }

      Refresher.prototype.refresh = function(e) {
        var params;
        if (e) {
          e.stopPropagation();
          e.preventDefault();
        }
        if (this._url) {
          this._container.addClass('working');
          params = {
            dataType: "html",
            beforeSend: this.prep,
            success: this.replace
          };
          if (this._method) {
            params.method = this._method;
            if (this._method.toLowerCase() === 'post' && this._data) {
              params.data = this._data;
            }
          }
          return $.ajax(this._url, params);
        } else {
          return console.error("Cannot refresh: no URL to fetch");
        }
      };

      Refresher.prototype.prep = function(xhr, settings) {
        xhr.setRequestHeader('X-PJAX', 'true');
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        this._container.addClass('waiting');
        return true;
      };

      Refresher.prototype.replace = function(data, textStatus, jqXHR) {
        var old_container, replacement;
        replacement = $(data);
        old_container = this._container;
        return old_container.fadeOut('fast', (function(_this) {
          return function() {
            replacement.hide().insertAfter(old_container);
            old_container.hide();
            replacement.show();
            old_container.trigger('refreshed', _this._container);
            old_container.remove();
            replacement.activate().signal_confirmation();
            return _this._container = replacement;
          };
        })(this));
      };

      return Refresher;

    })();
    $.fn.removes = function() {
      return this.each(function() {
        var affected, removed;
        removed = $(this).attr('data-removed') || ".holder";
        affected = $(this).attr('data-affected');
        return $(this).remote({
          on_success: (function(_this) {
            return function(response) {
              if ($(_this).parents('.menu').first().length === 1) {
                $(_this).parents('.menu').first().fadeOut('fast', function() {});
                return $(removed).remove();
              } else {
                return $(_this).parents(removed).first().fadeOut('fast', function() {
                  $(this).remove();
                  return $(affected).trigger("refresh");
                });
              }
            };
          })(this)
        });
      });
    };
    $.fn.removes_all = function() {
      return this.each(function() {
        var affected, removed;
        removed = $(this).attr('data-removed');
        affected = $(this).attr('data-affected');
        return $(this).remote({
          on_success: (function(_this) {
            return function(response) {
              return $(removed).fadeOut('fast', function() {
                $(this).remove();
                return $(affected).trigger("refresh");
              });
            };
          })(this)
        });
      });
    };
    $.fn.affects = function() {
      return this.each(function() {
        var affected;
        affected = $(this).attr('data-affected');
        return $(this).remote({
          on_success: (function(_this) {
            return function(response) {
              return $(affected).trigger("refresh");
            };
          })(this)
        });
      });
    };
    $.fn.closes = function() {
      return this.click(function(e) {
        e.preventDefault();
        return $(this).trigger('close');
      });
    };
    $.fn.replace_with_remote_content = function(selector, opts) {
      var options;
      if (selector == null) {
        selector = '.holder';
      }
      options = $.extend({
        force: false,
        confirm: false,
        slide: false,
        pjax: true,
        credentials: false
      }, opts);
      return this.each(function() {
        var $el, affected, container;
        $el = $(this);
        container = $el.attr('data-replaced') || selector;
        affected = $el.attr('data-affected');
        $el.remote({
          credentials: options.credentials,
          pjax: options.pjax,
          on_success: (function(_this) {
            return function(e, response) {
              var replaced, replacement;
              if (response == null) {
                response = e;
              }
              replaced = container === "self" ? $el : $el.self_or_ancestor(container).last();
              replacement = $(response).insertAfter(replaced);
              console.log('response', response);
              console.log('replaced', replaced);
              console.log('replacement', replacement);
              if (replaced[0].id === 'new_round') {
                if (replaced != null) {
                  replaced.hide();
                }
              } else {
                if (replaced != null) {
                  replaced.remove();
                }
              }
              replacement.activate();
              if (options.slide) {
                replacement.hide().slideDown();
              }
              if (options.confirm) {
                replacement.signal_confirmation();
              }
              replacement.trigger('updated');
              $(affected).trigger('refresh');
              return $('.cancel_new_round').bind('click', function(e) {
                if (replacement != null) {
                  replacement.hide();
                }
                return replaced != null ? replaced.show() : void 0;
              });
            };
          })(this)
        });
        if (options.force) {
          return $.rails.handleRemote($el);
        }
      });
    };
    $.fn.update_main_content = function(selector, opts) {
      var options;
      if (selector == null) {
        selector = '.holder';
      }
      options = $.extend({
        force: false,
        confirm: false,
        slide: false,
        pjax: true,
        credentials: false
      }, opts);
      return this.each(function() {
        var $el, container;
        $el = $(this);
        container = selector;
        return $el.remote({
          credentials: options.credentials,
          pjax: options.pjax,
          on_success: (function(_this) {
            return function(e, response) {
              var className, id;
              if (response == null) {
                response = e;
              }
              className = $(response).attr("class");
              id = $(response).attr("id");
              _this._selector = $("[data-menu=\"" + id + "\"]");
              $(_this._selector).removeClass().addClass(className);
              return $(".menu").hide();
            };
          })(this)
        });
      });
    };
    $.fn.reinviter = function() {
      return this.each(function() {
        var $el;
        $el = $(this);
        $el.data('method', 'put');
        return $el.remote({
          on_request: (function(_this) {
            return function() {
              return $el.addClass('waiting');
            };
          })(this),
          on_success: (function(_this) {
            return function(e, r) {
              var confirmation;
              $el.removeClass('waiting').addClass('reinvited');
              $el.find('svg use').attr('xlink:href', '#tick_symbol');
              if (confirmation = $el.data('confirmation')) {
                return $el.find('span.label').text(confirmation);
              }
            };
          })(this),
          on_error: function(xhr, status, error) {
            $el.removeClass('waiting');
            $el.addClass('erratic');
            return $el.find('span.label').text(error);
          }
        });
      });
    };
    $.fn.submitter = function() {
      return this.each(function() {
        var button;
        button = $(this);
        return button.parents('form').bind("submit", function(e) {
          return button.addClass('waiting').text('Please wait').bind("click", (function(_this) {
            return function(e) {
              if (e) {
                return e.preventDefault();
              }
            };
          })(this));
        });
      });
    };
    $.fn.appends_fields = function(appended) {
      return this.each(function() {
        var $link, affected, limit, set_visibility;
        $link = $(this);
        affected = appended != null ? appended : $link.attr('data-affected');
        limit = parseInt($link.attr('data-limit') || 0);
        set_visibility = function() {
          var counter;
          counter = $(affected).find('fieldset.repeating').length;
          if (limit && counter >= limit) {
            return $link.hide();
          } else {
            return $link.show();
          }
        };
        set_visibility();
        return $link.remote({
          on_request: (function(_this) {
            return function(e, xhr, settings) {
              return $link.addClass('working');
            };
          })(this),
          on_error: (function(_this) {
            return function() {
              return $link.removeClass('working').addClass('erratic');
            };
          })(this),
          on_success: (function(_this) {
            return function(e, response) {
              var addition, counter, offset;
              if (!response) {
                response = e;
                e = void 0;
              }
              if (e != null) {
                e.stopPropagation();
              }
              $link.removeClass('working');
              counter = $(affected).find('fieldset').length;
              if (offset = $(affected).data('offset')) {
                counter += parseInt(offset);
              }
              addition = $(response.replace(/field_counter/g, counter));
              addition.hide().appendTo(affected).slideDown('fast');
              addition.activate();
              addition.trigger('appended', addition);
              return set_visibility();
            };
          })(this)
        });
      });
    };
    $.fn.removes_fields = function() {
      return this.each(function() {
        var clipper, ref, selector;
        clipper = $(this);
        selector = (ref = clipper.attr('data-holder')) != null ? ref : '.holder';
        return clipper.bind('click', function(e) {
          var holder;
          e.preventDefault();
          holder = clipper.parents(selector).first();
          return holder.slideUp('fast', function() {
            var delete_field;
            delete_field = holder.find('input[data-role="destroy"]');
            if (delete_field.length) {
              delete_field.val(1);
              return holder.find('input[type="file"]').disable();
            } else {
              return holder.remove();
            }
          });
        });
      });
    };
    $.fn.setter = function() {
      return this.each(function() {
        return new Setter(this);
      });
    };
    Setter = (function() {
      function Setter(element, _root, _property) {
        var ref, ref1;
        this._root = _root;
        this._property = _property;
        this.update = bind(this.update, this);
        this.error = bind(this.error, this);
        this.toggle = bind(this.toggle, this);
        this.data = bind(this.data, this);
        this._link = $(element);
        if (this._root == null) {
          this._root = this._link.attr('data-object');
        }
        if (this._property == null) {
          this._property = this._link.attr('data-property');
        }
        this._positive = (ref = this._link.attr('data-positive')) != null ? ref : true;
        this._negative = (ref1 = this._link.attr('data-negative')) != null ? ref1 : false;
        this._affected = this._link.attr('data-affected');
        this._link.bind("click", this.toggle);
      }

      Setter.prototype.data = function(e) {
        var data, value;
        data = {};
        value = this._link.hasClass('yes') ? this._negative : this._positive;
        data[this._root] = {};
        data[this._root][this._property] = value;
        data['_method'] = "PUT";
        return data;
      };

      Setter.prototype.toggle = function(e) {
        var data, value;
        if (e) {
          e.preventDefault();
        }
        value = !this._link.hasClass('yes');
        data = {};
        this._link.addClass('waiting');
        return $.ajax({
          url: this._link.attr('href'),
          type: "POST",
          data: this.data(),
          success: this.update,
          error: this.error
        });
      };

      Setter.prototype.error = function(xhr, status, error) {
        return this._link.removeClass('waiting').signal_error();
      };

      Setter.prototype.update = function(response) {
        this._link.removeClass('waiting');
        if (this._link.hasClass('yes')) {
          this._link.addClass('no').removeClass('yes');
        } else {
          this._link.addClass('yes').removeClass('no');
        }
        return $(this._affected).refresh();
      };

      return Setter;

    })();
    $.fn.toggle_visibility = function() {
      return this.each(function() {
        return new Toggle(this, $(this).attr('data-affected'));
      });
    };
    Toggle = (function() {
      function Toggle(element, _selector, _name) {
        var cookie;
        this._selector = _selector;
        this._name = _name;
        this.store = bind(this.store, this);
        this.hide = bind(this.hide, this);
        this.slideUp = bind(this.slideUp, this);
        this.show = bind(this.show, this);
        this.slideDown = bind(this.slideDown, this);
        this.toggle = bind(this.toggle, this);
        this.apply = bind(this.apply, this);
        this._container = $(element);
        this._remembered = this._container.attr('data-remembered') !== 'false';
        if (this._name == null) {
          this._name = "droom_" + this._selector + "_state";
        }
        this._showing_text = this._container.text().replace('show', 'hide').replace('Show', 'Hide').replace('more', 'less').replace('More', 'Less');
        this._hiding_text = this._showing_text.replace('hide', 'show').replace('Hide', 'Show').replace('less', 'more').replace('Less', 'More');
        this._container.click(this.toggle);
        if (this._remembered && (cookie = $.cookie(this._name))) {
          this._showing = cookie === "showing";
          this.apply();
        } else {
          this._showing = $(this._selector).is(":visible");
          this.store();
        }
      }

      Toggle.prototype.apply = function(e) {
        if (e) {
          e.preventDefault();
        }
        if (this._showing) {
          return this.show();
        } else {
          return this.hide();
        }
      };

      Toggle.prototype.toggle = function(e) {
        if (e) {
          e.preventDefault();
        }
        if (this._showing) {
          return this.slideUp();
        } else {
          return this.slideDown();
        }
      };

      Toggle.prototype.slideDown = function() {
        this._container.addClass('showing');
        return $(this._selector).slideDown((function(_this) {
          return function() {
            _this.show();
            return _this._container.trigger('toggled');
          };
        })(this));
      };

      Toggle.prototype.show = function() {
        $(this._selector).show();
        this._container.addClass('showing');
        this._container.text(this._showing_text);
        this._showing = true;
        return this.store();
      };

      Toggle.prototype.slideUp = function() {
        return $(this._selector).slideUp((function(_this) {
          return function() {
            _this.hide();
            return _this._container.trigger('toggled');
          };
        })(this));
      };

      Toggle.prototype.hide = function() {
        $(this._selector).hide();
        this._container.removeClass('showing');
        this._container.text(this._hiding_text);
        this._showing = false;
        return this.store();
      };

      Toggle.prototype.store = function() {
        var value;
        if (this._remembered) {
          value = this._showing ? "showing" : "hidden";
          return $.cookie(this._name, value, {
            path: '/'
          });
        }
      };

      return Toggle;

    })();
    $.fn.collapser = function(options) {
      this.each(function() {
        return new Collapser(this, options);
      });
      return this;
    };
    Collapser = (function() {
      function Collapser(element, opts) {
        this.show = bind(this.show, this);
        this.hide = bind(this.hide, this);
        this.toggle = bind(this.toggle, this);
        this.set = bind(this.set, this);
        this.container = $(element);
        this.options = $.extend({
          toggle: "a.name",
          body: ".detail",
          preview: ".preview"
        }, opts);
        this.id = this.container.attr('id');
        this["switch"] = this.container.find(this.options.toggle);
        this.body = this.container.find(this.options.body);
        this.preview = this.container.find(this.options.preview);
        this["switch"].click(this.toggle);
        this.set();
      }

      Collapser.prototype.set = function() {
        if (this.container.hasClass("open")) {
          return this.show();
        } else {
          return this.hide();
        }
      };

      Collapser.prototype.toggle = function(e) {
        if (e) {
          e.preventDefault();
        }
        if (this.container.hasClass("open")) {
          return this.hide();
        } else {
          return this.show();
        }
      };

      Collapser.prototype.hide = function() {
        this.container.removeClass('open');
        this.preview.show().css('position', 'relative');
        return this.body.stop().slideUp({
          duration: 'slow',
          easing: 'glide',
          complete: (function(_this) {
            return function() {
              return _this.body.hide();
            };
          })(this)
        });
      };

      Collapser.prototype.show = function() {
        this.container.addClass('open');
        this.preview.css('position', 'absolute');
        return this.body.stop().slideDown({
          duration: 'normal',
          easing: 'boing',
          complete: (function(_this) {
            return function() {
              return _this.preview.hide().css('position', 'relative');
            };
          })(this)
        });
      };

      return Collapser;

    })();
    $.fn.reveals = function() {
      return this.each(function() {
        return new Revealer(this);
      });
    };
    Revealer = (function() {
      function Revealer(element) {
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.set = bind(this.set, this);
        this._input = $(element);
        this._affected = this._input.attr('data-affected');
        this._converse = this._input.attr('data-converse');
        this._input.bind("click", this.set);
        this.set();
      }

      Revealer.prototype.set = function() {
        if (this._input.is(":checked")) {
          return this.show();
        } else {
          return this.hide();
        }
      };

      Revealer.prototype.show = function(e) {
        $(this._affected).stop().slideDown();
        $(this._affected).find('input').attr('disabled', false);
        $(this._converse).stop().slideUp();
        return $(this._converse).find('input').attr('disabled', true);
      };

      Revealer.prototype.hide = function(e) {
        $(this._affected).stop().slideUp();
        $(this._affected).find('input').attr('disabled', true);
        $(this._converse).stop().slideDown();
        return $(this._converse).find('input').attr('disabled', false);
      };

      return Revealer;

    })();
    Alternator = (function() {
      function Alternator(element) {
        this.revert = bind(this.revert, this);
        this.flip = bind(this.flip, this);
        this._container = $(element);
        this._selector = this._container.attr("data-selector");
        this._alternate = this._container.siblings(this._selector);
        this.revert();
      }

      Alternator.prototype.flip = function(e) {
        if (e) {
          e.preventDefault();
        }
        this._container.after(this._alternate);
        this._container.remove();
        return this._alternate.find('a').click(this.revert);
      };

      Alternator.prototype.revert = function(e) {
        if (e) {
          e.preventDefault();
        }
        this._alternate.before(this._container);
        this._alternate.remove();
        return this._container.find('a').click(this.flip);
      };

      return Alternator;

    })();
    $.fn.alternator = function() {
      return this.each(function() {
        return new Alternator(this);
      });
    };
    $.fn.hover_table = function() {
      return this.each(function() {
        return $(this).find('td').hover_cell();
      });
    };
    $.fn.hover_cell = function() {
      return this.each(function() {
        var classes;
        classes = this.className.split(' ').join('.');
        $(this).bind("mouseenter", function(e) {
          return $("." + classes).addClass('hover');
        });
        return $(this).bind("mouseleave", function(e) {
          return $("." + classes).removeClass('hover');
        });
      });
    };
    $.fn.copier = function() {
      return this.each(function() {
        var clipboard;
        clipboard = new ClipboardJS(this);
        return clipboard.on('success', function(e) {
          $(e.trigger).signal_confirmation();
          return console.log("copied", e.text);
        });
      });
    };
    $.fn.search = function() {
      return this.each(function() {
        return new Search(this);
      });
    };
    Search = (function() {
      function Search(element) {
        this.submit = bind(this.submit, this);
        this.form = $(element);
        this.search_box = this.form.find(".search_box");
        this.container = $(".search_results");
        this.filters = this.form.find("input[type='checkbox']");
        this.search_box.on("keyup", this.submit);
        this.filters.on("change", this.submit);
      }

      Search.prototype.submit = function() {
        return $.ajax({
          url: (this.form.attr('action')) + "?" + (this.form.serialize()),
          type: "GET",
          dataType: "script",
          complete: (function(_this) {
            return function(data) {
              _this.container.replaceWith(data.responseText);
              return _this.container = $(".search_results");
            };
          })(this)
        });
      };

      return Search;

    })();
    $.fn.search_filter = function() {
      this.each(function() {
        return new Filter(this);
      });
      return this;
    };
    Filter = (function() {
      function Filter(element) {
        this.filter = bind(this.filter, this);
        this.clearQuery = bind(this.clearQuery, this);
        this.setQuery = bind(this.setQuery, this);
        this.setDefilter = bind(this.setDefilter, this);
        this._container = $(element);
        this._defilter = $('<a href="#" class="defilter" />').insertAfter(this._container);
        this._affected = this._container.attr('data-affected');
        this.setDefilter();
        this._container.bind("keyup", this.setQuery);
        this._defilter.bind("click", this.clearQuery);
      }

      Filter.prototype.setDefilter = function() {
        if (this._container.val()) {
          return this._defilter.show();
        } else {
          return this._defilter.hide();
        }
      };

      Filter.prototype.setQuery = function(e) {
        var kc;
        kc = e.which;
        if ((kc === 8) || (kc === 46) || ((47 < kc && kc < 91)) || ((96 < kc && kc < 112)) || (kc > 145)) {
          this.setDefilter();
          return this.filter();
        }
      };

      Filter.prototype.clearQuery = function(e) {
        if (e) {
          e.preventDefault();
        }
        this._container.val("");
        this.setDefilter();
        return this.filter();
      };

      Filter.prototype.filter = function() {
        return $(this._affected).trigger("filter", this._container.val());
      };

      return Filter;

    })();
    $.size_to_fit = function(e) {
      var container, l, size;
      container = $(this);
      l = container.val().length;
      size = l ? ((560.0 / (2 * l + 150.0)) + 0.25).toFixed(2) : 1;
      return container.stop().animate({
        'font-size': size + "em",
        width: 532,
        height: 290
      }, {
        queue: false,
        duration: 100
      });
    };
    return $.fn.self_sizes = function() {
      return this.each(function() {
        $(this).bind("keyup", $.size_to_fit);
        $(this).bind("change", $.size_to_fit);
        return $.size_to_fit.apply(this);
      });
    };
  });

}).call(this);