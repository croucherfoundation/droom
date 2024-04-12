(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  jQuery(function($) {
    var Calendar, CaptiveForm, DatePicker, Draggable, DroomImagePicker, Dropdown, FilePicker, Folder, Pager, PasswordFieldset, PasswordMeter, ScorePicker, ScoreShower, Slider, SlugField, Subordinate, Suggester, TimePicker, YoutubeSuggester;
    $.fn.date_picker = function() {
      return this.each(function() {
        return new DatePicker(this);
      });
    };
    DatePicker = (function() {
      DatePicker.month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      function DatePicker(element) {
        this.setDate = bind(this.setDate, this);
        this.getDate = bind(this.getDate, this);
        var d, initial_date, iso_date, m, ref, ref1, view, y;
        this._container = $(element);
        view = (ref = this._container.attr("data-view")) != null ? ref : 'days';
        if (this._container.is("input")) {
          this._field = this._container;
          this._container = this._field.clone().attr('name', 'display-date').insertAfter(this._field);
          if (iso_date = this._field.val()) {
            ref1 = iso_date.split('-'), y = ref1[0], m = ref1[1], d = ref1[2];
            this._container.val([d, DatePicker.month_names[m - 1], y].join(' '));
          }
          this._field.hide();
          this._event = 'focus';
          this._simple = true;
        } else {
          this._field = this._container.find('input');
          this._event = 'click';
          this._simple = false;
          this._mon = this._container.find('span.mon');
          this._dom = this._container.find('span.dom');
          this._year = this._container.find('span.year');
        }
        initial_date = this.getDate();
        this._container.DatePicker({
          calendars: 1,
          date: initial_date,
          current: initial_date,
          view: view,
          position: 'bottom',
          showOn: this._event,
          onChange: this.setDate
        });
      }

      DatePicker.prototype.getDate = function() {
        var value;
        if (value = this._field.val()) {
          return new Date(Date.parse(value));
        }
      };

      DatePicker.prototype.setDate = function(date) {
        var d, m, realDateString, y;
        $('.datepicker').hide();
        if (date) {
          d = $.zeroPad(date.getDate());
          m = date.getMonth();
          y = date.getFullYear();
          realDateString = [y, $.zeroPad(m + 1), $.zeroPad(d)].join('-');
          this._field.val(realDateString);
          if (this._simple) {
            return this._container.val([d, DatePicker.month_names[m], y].join(' '));
          } else {
            this._dom.text(d);
            this._mon.text(DatePicker.month_names[m]);
            return this._year.text(y);
          }
        }
      };

      return DatePicker;

    })();
    TimePicker = (function() {
      function TimePicker(element) {
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.change = bind(this.change, this);
        this.select = bind(this.select, this);
        var i, j, times;
        this.field = $(element);
        this.holder = $('<div class="timepicker" />');
        this.dropdown = new Dropdown(this.field, {
          on_select: this.select,
          on_keyup: this.change
        });
        times = [];
        for (i = j = 0; j <= 24; i = ++j) {
          times.push({
            value: i + ":00"
          });
          times.push({
            value: i + ":30"
          });
        }
        this.dropdown.populate(times);
        this.field.focus(this.show);
        this.field.blur(this.hide);
      }

      TimePicker.prototype.select = function(value) {
        this.field.val(value);
        return this.field.trigger('change');
      };

      TimePicker.prototype.change = function(e) {
        return this.dropdown.match(this.field.val());
      };

      TimePicker.prototype.show = function(e) {
        return this.dropdown.show();
      };

      TimePicker.prototype.hide = function(e) {
        return this.dropdown.hide();
      };

      return TimePicker;

    })();
    $.fn.time_picker = function() {
      return this.each(function() {
        return new TimePicker(this);
      });
    };
    $.fn.file_picker = function() {
      return this.each(function() {
        return new FilePicker(this);
      });
    };
    $.fn.click_proxy = function() {
      return this.each(function() {
        var target;
        target = $(this).attr('data-affected');
        return $(this).bind("click", function(e) {
          if (e) {
            e.preventDefault();
          }
          return $(target).trigger("click");
        });
      });
    };
    FilePicker = (function() {
      function FilePicker(element) {
        this.remove = bind(this.remove, this);
        this.remover = bind(this.remover, this);
        this.progress = bind(this.progress, this);
        this.initProgress = bind(this.initProgress, this);
        this.display = bind(this.display, this);
        this.picked = bind(this.picked, this);
        this.extensions = bind(this.extensions, this);
        this.picker = bind(this.picker, this);
        var ref;
        this._container = $(element);
        this._form = this._container.parents('form');
        this._link = this._container.find('a[data-action="pick"]');
        this._filefield = this._container.find('input[type="file"]');
        this._file = null;
        this._filename = (ref = $('input.name').val()) != null ? ref : "";
        this._ext = "";
        this._fields = this._container.siblings('.non-file-data');
        this._form.bind('remote:upload', this.initProgress);
        this._form.bind('remote:progress', this.progress);
        this._link.bind('click', this.picker);
        this._filefield.bind('change', this.picked);
      }

      FilePicker.prototype.picker = function(e) {
        if (e) {
          e.preventDefault();
        }
        return this._filefield.click();
      };

      FilePicker.prototype.extensions = function() {
        return this._extensions != null ? this._extensions : this._extensions = ['doc', 'docx', 'pdf', 'xls', 'xlsx', 'jpg', 'png'];
      };

      FilePicker.prototype.picked = function(e) {
        var files, ref;
        this._link.removeClass(this.extensions().join(' '));
        if (files = this._filefield[0].files) {
          if (this._file = files.item(0)) {
            this._previous_filename = (ref = this._filename) != null ? ref : "";
            this._filename = this._file.name.split(/[\/\\]/).pop();
            this._ext = this._filename.split('.').pop();
            return this.display();
          }
        }
      };

      FilePicker.prototype.display = function() {
        var arr, ext, filename, ref;
        if (ref = this._ext, indexOf.call(this.extensions(), ref) >= 0) {
          this._link.addClass(this._ext);
        }
        if ($('input.name').val() === this._previous_filename) {
          this._form.find('input.name').val(this._filename).change();
          if (this._form.find('#document-info')) {
            arr = this._filename.split('.');
            ext = arr.last();
            arr.length = arr.length - 1;
            this._form.find('input.filename');
            filename = this._form.find('input.filename');
            if (filename.hasClass('file_with_extension')) {
              filename.val(this._filename);
            } else {
              filename.val(arr.join('.'));
            }
            return this._form.find('input.extension').val("." + ext);
          }
        }
      };

      FilePicker.prototype.initProgress = function(e, xhr, settings) {
        if (this._file != null) {
          this._fields.hide();
          this._notifier = $('<div class="notifier"></div>').appendTo(this._form);
          this._label = $('<h3 class="filename"></h3>').appendTo(this._notifier);
          this._progress = $('<div class="progress"></div>').appendTo(this._notifier);
          this._bar = $('<div class="bar"></div>').appendTo(this._progress);
          this._label.text(this._filename);
        }
        return true;
      };

      FilePicker.prototype.progress = function(e, prog) {
        var full_width, progress_width;
        if ((this._file != null) && prog.lengthComputable) {
          full_width = this._progress.width();
          progress_width = Math.round(full_width * prog.loaded / prog.total);
          return this._bar.width(progress_width);
        }
      };

      FilePicker.prototype.remover = function() {
        if (this._remover == null) {
          this._remover = $('<a href="#" class="remover" />').insertAfter(this._link);
          this._remover.click(this.remove);
        }
        return this._remover;
      };

      FilePicker.prototype.remove = function(e) {
        var old_ff, ref;
        if (e) {
          e.preventDefault();
        }
        old_ff = this._filefield;
        this._filefield = old_ff.clone().insertAfter(old_ff);
        this._filefield.bind('change', this.picked);
        old_ff.remove();
        if ($('input.name').val() === this._filename) {
          this._form.find('input.name').val("");
        }
        this._filename = "";
        this._ext = "";
        if ((ref = this._remover) != null) {
          ref.hide();
        }
        return this._link.css({
          "background-image": this._original_background
        });
      };

      return FilePicker;

    })();
    $.fn.droom_image_picker = function() {
      return this.each(function() {
        return new DroomImagePicker(this);
      });
    };
    DroomImagePicker = (function(superClass) {
      extend(DroomImagePicker, superClass);

      function DroomImagePicker() {
        this.display = bind(this.display, this);
        return DroomImagePicker.__super__.constructor.apply(this, arguments);
      }

      DroomImagePicker.prototype.display = function() {
        var reader;
        if ($('input.name').val() === this._previous_filename) {
          this._form.find('input.name').val(this._filename);
        }
        if (this._original_background == null) {
          this._original_background = this._link.css("background-image");
        }
        reader = new FileReader();
        reader.onload = (function(_this) {
          return function(e) {
            _this._link.css({
              "background-image": "url(" + reader.result + ")"
            });
            return _this.remover().show();
          };
        })(this);
        return reader.readAsDataURL(this._file);
      };

      return DroomImagePicker;

    })(FilePicker);
    $.fn.score_picker = function() {
      return this.each(function() {
        return new ScorePicker(this);
      });
    };
    ScorePicker = (function() {
      function ScorePicker(element) {
        this.set = bind(this.set, this);
        this.unhover = bind(this.unhover, this);
        this.hover = bind(this.hover, this);
        var i;
        this._field = $(element);
        this._container = $('<div class="starpicker" />');
        this._value = this._field.val();
        this._value = (function() {
          var j, results1;
          results1 = [];
          for (i = j = 1; j <= 5; i = ++j) {
            results1.push((function(_this) {
              return function(i) {
                var star;
                star = $('<span class="star" />');
                star.attr('data-score', i);
                star.bind("mouseover", function(e) {
                  return _this.hover(e, star);
                });
                star.bind("mouseout", function(e) {
                  return _this.unhover(e, star);
                });
                star.bind("click", function(e) {
                  return _this.set(e, star);
                });
                return _this._container.append(star);
              };
            })(this)(i));
          }
          return results1;
        }).call(this);
        this._stars = this._container.find('span.star');
        this._field.after(this._container);
        this._field.hide();
      }

      ScorePicker.prototype.hover = function(e, star) {
        var i;
        this.unhover();
        i = parseInt(star.attr('data-score'));
        return this._stars.slice(0, i).addClass('hovered');
      };

      ScorePicker.prototype.unhover = function(e, star) {
        return this._stars.removeClass('hovered');
      };

      ScorePicker.prototype.set = function(e, star) {
        var i;
        if (e) {
          e.preventDefault;
        }
        this.unhover();
        i = parseInt(star.attr('data-score'));
        this._stars.removeClass('selected');
        this._stars.slice(0, i).addClass('selected');
        return this._field.val(i);
      };

      return ScorePicker;

    })();
    $.fn.password_fieldset = function() {
      if (this.length) {
        return new PasswordFieldset(this);
      }
    };
    PasswordFieldset = (function() {
      function PasswordFieldset(element) {
        this.unsubmittable = bind(this.unsubmittable, this);
        this.submittable = bind(this.submittable, this);
        this.unconfirmable = bind(this.unconfirmable, this);
        this.confirmable = bind(this.confirmable, this);
        this.valid = bind(this.valid, this);
        this.empty = bind(this.empty, this);
        this.confirmed = bind(this.confirmed, this);
        this.required = bind(this.required, this);
        this.checkConfirmation = bind(this.checkConfirmation, this);
        this.checkPassword = bind(this.checkPassword, this);
        var meter_holder;
        this.fieldset = $(element);
        this.password_field = this.fieldset.find('input[data-role="password"]');
        this.confirmation_block = this.fieldset.find('[data-role="confirmation"]');
        this.confirmation_field = this.confirmation_block.find('input');
        this.confirmation_field.bind('input', this.checkConfirmation);
        this.submitter = this.fieldset.parents('form').find('input[type="submit"]');
        meter_holder = this.fieldset.find('[data-role="meter"]');
        if (meter_holder.length) {
          this.meter = new PasswordMeter(meter_holder);
        }
        this.password_field.bind('input', this.checkPassword);
        this.checkPassword();
      }

      PasswordFieldset.prototype.checkPassword = function() {
        var ok, password, ref, ref1, ref2;
        if (this.empty()) {
          this.unconfirmable();
          this.password_field.removeClass('valid invalid');
          if ((ref = this.meter) != null) {
            ref.clear();
          }
          if (this.required()) {
            this.unsubmittable();
          } else {
            this.submittable();
          }
          return false;
        } else {
          password = this.password_field.val();
          ok = false;
          if (password.length < 6) {
            if ((ref1 = this.meter) != null) {
              ref1.tooShort();
            }
          } else {
            if ((ref2 = this.meter) != null) {
              ref2.check(password);
            }
            ok = true;
          }
          if (ok) {
            this.password_field.removeClass('invalid').addClass('valid');
            this.confirmable();
          } else {
            this.password_field.removeClass('valid').addClass('invalid');
            this.unconfirmable();
          }
          this.checkConfirmation();
          return ok;
        }
      };

      PasswordFieldset.prototype.checkConfirmation = function() {
        if (this.confirmed()) {
          this.confirmation_field.addClass('valid').removeClass('invalid');
          return this.submittable();
        } else {
          this.confirmation_field.removeClass('valid').addClass('invalid');
          if (!(this.empty() && !this.required())) {
            return this.unsubmittable();
          }
        }
      };

      PasswordFieldset.prototype.required = function() {
        return !!this.password_field.attr('required');
      };

      PasswordFieldset.prototype.confirmed = function() {
        return this.confirmation_field.val() === this.password_field.val();
      };

      PasswordFieldset.prototype.empty = function() {
        return this.password_field.val() === "";
      };

      PasswordFieldset.prototype.valid = function() {
        return this.confirmed() && (!this.empty() || !this.required());
      };

      PasswordFieldset.prototype.confirmable = function() {
        this.confirmation_field.attr('required', true);
        this.confirmation_block.addClass('available');
        return this.unsubmittable();
      };

      PasswordFieldset.prototype.unconfirmable = function() {
        this.confirmation_block.removeClass('available');
        this.confirmation_field.attr('required', false);
        return this.unsubmittable();
      };

      PasswordFieldset.prototype.submittable = function() {
        return this.submitter.enable();
      };

      PasswordFieldset.prototype.unsubmittable = function() {
        return this.submitter.disable();
      };

      return PasswordFieldset;

    })();
    $.fn.password_meter = function() {
      this.each(function() {
        return new PasswordMeter(this);
      });
      return this;
    };
    PasswordMeter = (function() {
      function PasswordMeter(element) {
        this.display = bind(this.display, this);
        this.check = bind(this.check, this);
        this.tooShort = bind(this.tooShort, this);
        this.clear = bind(this.clear, this);
        this._container = $(element);
        this._warnings = this._container.find('[data-role="warnings"]');
        this._suggestions = this._container.find('[data-role="suggestions"]');
        this._gauge = this._container.find('[data-role="gauge"]');
        this._score = this._container.find('[data-role="score"]');
        this._notes = this._container.find('[data-role="notes"]');
        this._original_warning = this._warnings.html();
        this._original_notes = this._notes.html();
        this._zxcvbn_ready = false;
        $.withZxcbvn((function(_this) {
          return function() {
            return _this._ready = true;
          };
        })(this));
      }

      PasswordMeter.prototype.clear = function() {
        this._warnings.text("");
        this._container.removeClass('s0 s1 s2 s3 s4 acceptable');
        this._notes.html(this._original_notes);
        return this._warnings.html(this._original_warning);
      };

      PasswordMeter.prototype.tooShort = function() {
        this.clear();
        this._container.addClass('s0');
        return this._warnings.text("Password too short.");
      };

      PasswordMeter.prototype.check = function(value) {
        var result;
        if (this._ready) {
          result = zxcvbn(value);
          this.display(result);
          return result.score;
        }
      };

      PasswordMeter.prototype.display = function(result) {
        var ref, ref1;
        if (result.score < 2) {
          if ((ref = result.feedback) != null ? ref.warning : void 0) {
            this._warnings.text(result.feedback.warning);
          }
          return this._suggestions.text((ref1 = result.feedback) != null ? ref1.suggestions : void 0);
        } else {
          return this._container.removeClass('s0 s1 s2 s3 s4 acceptable');
        }
      };

      return PasswordMeter;

    })();
    $.fn.captive = function(options) {
      this.each(function() {
        return new CaptiveForm(this, options);
      });
      return this;
    };
    $.fn.filter_form = function(options) {
      this.each(function() {
        return new CaptiveForm(this, {
          fast: true,
          into: "#found",
          auto: false,
          history: false
        });
      });
      return this;
    };
    $.fn.table_filter_form = function(options) {
      this.each(function() {
        return new CaptiveForm(this, {
          fast: true,
          into: "table",
          auto: false,
          history: true
        });
      });
      return this;
    };
    $.fn.quick_search_form = function(options) {
      this.each(function() {
        var defaults;
        defaults = {
          fast: true,
          into: "#found",
          auto: false,
          history: false
        };
        return new CaptiveForm(this, _.extend(defaults, options));
      });
      return this;
    };
    $.fn.suggestion_form = function(options) {
      this.each(function() {
        return new CaptiveForm(this, {
          fast: true,
          auto: false,
          into: "#suggestion_box",
          history: false
        });
      });
      return this;
    };
    $.fn.faceting_search = function(options) {
      var defaults;
      defaults = {
        fast: ".facet",
        history: true,
        threshold: 4
      };
      this.each(function() {
        return new CaptiveForm(this, _.extend(defaults, options));
      });
      return this;
    };
    CaptiveForm = (function() {
      CaptiveForm.default_options = {
        fast: false,
        auto: false,
        threshold: 3,
        history: false
      };

      function CaptiveForm(element, opts) {
        this.restoreState = bind(this.restoreState, this);
        this.saveState = bind(this.saveState, this);
        this.revert = bind(this.revert, this);
        this.display = bind(this.display, this);
        this.capture = bind(this.capture, this);
        this.prepare = bind(this.prepare, this);
        this.submit = bind(this.submit, this);
        this.page = bind(this.page, this);
        this.serialize = bind(this.serialize, this);
        this.clicked = bind(this.clicked, this);
        this.changed = bind(this.changed, this);
        this.keyed = bind(this.keyed, this);
        this.bindInputs = bind(this.bindInputs, this);
        this.bindLinks = bind(this.bindLinks, this);
        this._form = $(element);
        this._options = $.extend(this.constructor.default_options, opts);
        this._historical = this._options.history || this._form.attr('data-historical');
        this._selector = this._form.attr('data-target') || this._options.into;
        this._container = $(this._selector);
        this._original_qs = this.serialize();
        this._original_content = this._container.html();
        this._request = null;
        this._inactive = false;
        this._cache = {};
        this._form.bind('refresh', (function(_this) {
          return function() {
            return _this._form.submit();
          };
        })(this));
        this._form.remote({
          on_request: this.prepare,
          on_cancel: this.cancel,
          on_success: this.capture
        });
        this.submit_soon = _.debounce(this.submit, 500);
        if (this._options.fast) {
          this.bindInputs(this._options.fast);
        }
        this._form.bind('refresh', this.changed);
        if (this._options.auto) {
          this.submit();
        } else {
          this.bindLinks();
        }
        if (this._historical) {
          this.saveState(this._original_content);
          $(window).bind('popstate', this.restoreState);
        }
        $.qf = this;
      }

      CaptiveForm.prototype.bindLinks = function() {
        this._container.find('a.cancel').click(this.revert);
        return this._container.find('.pagination a').click(this.page);
      };

      CaptiveForm.prototype.bindInputs = function(selector) {
        if (typeof selector === "string") {
          return this._form.find(selector).bind('change', this.changed);
        } else {
          this._form.find('input[type="search"]').bind('keyup', this.changed);
          this._form.find('input[type="search"]').bind('change', this.changed);
          this._form.find('input[type="text"]').bind('keyup', this.keyed);
          this._form.find('input[type="text"]').bind('change', this.changed);
          this._form.find('select').bind('change', this.changed);
          this._form.find('input[type="radio"]').bind('click', this.clicked);
          return this._form.find('input[type="checkbox"]').bind('click', this.clicked);
        }
      };

      CaptiveForm.prototype.keyed = function(e) {
        var k;
        k = e.which;
        if (k === 13) {
          this.submit(e);
        }
        if ((k >= 46 && k <= 90) || (k >= 96 && k <= 111) || k === 8) {
          return this.changed(e);
        }
      };

      CaptiveForm.prototype.changed = function(e) {
        if (!this._inactive) {
          return this.submit_soon();
        }
      };

      CaptiveForm.prototype.clicked = function(e) {
        if (!this._inactive) {
          return this.submit_soon();
        }
      };

      CaptiveForm.prototype.serialize = function() {
        var parameters;
        parameters = [];
        this._form.find(":input").each((function(_this) {
          return function(i, f) {
            var field;
            field = $(f);
            if (field.val() !== "") {
              return parameters.push(field.serialize());
            }
          };
        })(this));
        return parameters.join('&');
      };

      CaptiveForm.prototype.page = function(e) {
        var a, href, p;
        if (e) {
          e.preventDefault();
        }
        a = $(e.target);
        href = a.attr('href');
        p = $.urlParam('page', href);
        this._form.find('input[name="page"]').val(p);
        return this.submit();
      };

      CaptiveForm.prototype.submit = function(e, nocache) {
        var qs;
        if (e) {
          e.preventDefault();
        }
        if (nocache == null) {
          nocache = false;
        }
        qs = this.serialize();
        if (!nocache && this._cache[qs]) {
          return this.display(this._cache[qs]);
        } else {
          return this._form.submit();
        }
      };

      CaptiveForm.prototype.prepare = function(xhr, settings) {
        return this._container.fadeTo("fast", 0.2);
      };

      CaptiveForm.prototype.capture = function(e, data, status, xhr) {
        this._cache[this.serialize()] = data;
        this.display(data);
        if (this._historical) {
          return this.saveState(data);
        }
      };

      CaptiveForm.prototype.display = function(results) {
        var replacement;
        replacement = $(results);
        this._container.empty().append(replacement).fadeTo("fast", 1);
        replacement.activate();
        replacement.find('a.cancel').click(this.revert);
        this.bindLinks();
        $("html, body").animate({
          scrollTop: 0
        }, "slow");
        return window.cacheFunc && window.cacheFunc();
      };

      CaptiveForm.prototype.revert = function(e) {
        return this.display(this._original_content);
      };

      CaptiveForm.prototype.saveState = function(results, qs) {
        var state, title, url;
        if (qs == null) {
          qs = this.serialize();
        }
        url = window.location.pathname + "?" + qs;
        title = document.title + ' search';
        state = {
          html: results,
          qs: qs
        };
        return history.pushState(state, title, url);
      };

      CaptiveForm.prototype.restoreState = function(e) {
        var event;
        event = e.originalEvent;
        if (e) {
          e.preventDefault();
        }
        if ((event.state != null) && (event.state.html != null)) {
          this.display(event.state.html);
          this._inactive = true;
          this._form.deserialize(event.state.qs);
          return this._inactive = false;
        }
      };

      return CaptiveForm;

    })();
    $.urlParam = function(name, url) {
      var results;
      if (url == null) {
        url = window.location.href;
      }
      results = new RegExp("[\\?&]" + name + "=([^&#]*)").exec(url);
      if (!results) {
        return false;
      }
      return decodeURIComponent(results[1]).replace(/\+/g, " ");
    };
    $.fn.quick_search_form = function() {
      return this.each(function() {
        var $form, $input, $stumbit, button_setter;
        $form = $(this);
        $input = $form.find('input[type="text"]');
        $stumbit = $form.find('a.submit');
        $stumbit.click(function(e) {
          if (e != null) {
            e.preventDefault();
          }
          return $form.trigger('submit');
        });
        button_setter = function() {
          var q, v;
          q = $.urlParam('q');
          v = $input.val();
          if (v && (v === q)) {
            return $form.addClass('cancellable').removeClass('submittable');
          } else if (v && v.length > 1) {
            return $form.removeClass('cancellable').addClass('submittable');
          } else {
            return $form.removeClass('cancellable submittable');
          }
        };
        $input.on("input", _.debounce(button_setter, 100));
        return button_setter();
      });
    };
    $.fn.subordinate = function() {
      return this.each(function() {
        return new Subordinate(this, {
          reversed: false
        });
      });
    };
    $.fn.insubordinate = function() {
      return this.each(function() {
        return new Subordinate(this, {
          reversed: true
        });
      });
    };
    Subordinate = (function() {
      function Subordinate(element, options) {
        var ref, selector;
        if (options == null) {
          options = {};
        }
        this.disable = bind(this.disable, this);
        this.enable = bind(this.enable, this);
        this.update = bind(this.update, this);
        this._container = $(element);
        this._reversed = (ref = options.reversed) != null ? ref : false;
        if (selector = this._container.attr('data-dependent').replace('.', '_')) {
          this._controller = $(selector);
          this._controller.bind('click', this.update);
          this.update();
        }
      }

      Subordinate.prototype.update = function() {
        if (this._reversed) {
          if (this._controller.is(":checked")) {
            return this.disable();
          } else {
            return this.enable();
          }
        } else {
          if (this._controller.is(":checked")) {
            return this.enable();
          } else {
            return this.disable();
          }
        }
      };

      Subordinate.prototype.enable = function() {
        this._container.enable();
        return this._container.find('input[type="text"]').first().focus();
      };

      Subordinate.prototype.disable = function() {
        return this._container.disable();
      };

      return Subordinate;

    })();
    $.fn.folder = function() {
      return this.each(function() {
        return new Folder(this);
      });
    };
    Folder = (function() {
      function Folder(element) {
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.toggle = bind(this.toggle, this);
        this.replace = bind(this.replace, this);
        this.set = bind(this.set, this);
        this._container = $(element);
        this._label = this._container.attr('data-label');
        this._list = this._container.children('ul.filing');
        if (this._list[0]) {
          this._container.children('a.folder').click(this.toggle);
          this.set();
        } else {
          this._container.children('a.folder').remote({
            on_success: this.replace
          });
        }
      }

      Folder.prototype.set = function(e) {
        if (e) {
          e.preventDefault();
        }
        if (this._container.hasClass('open')) {
          this._state = "open";
        }
        if (this._state === "open") {
          this._container.addClass("open");
          return this._list.show();
        } else {
          this._container.removeClass("open");
          return this._list.hide();
        }
      };

      Folder.prototype.replace = function(e, response) {
        var replacement;
        replacement = $(response);
        this._container.after(replacement);
        this._container.remove();
        return replacement.activate();
      };

      Folder.prototype.toggle = function(e) {
        if (e) {
          e.preventDefault();
          e.stopPropagation();
        }
        if (this._container.hasClass('open')) {
          return this.hide();
        } else {
          return this.show();
        }
      };

      Folder.prototype.show = function(e) {
        if (e) {
          e.preventDefault();
        }
        this._container.addClass('open');
        return this._list.stop().slideDown("fast");
      };

      Folder.prototype.hide = function(e) {
        if (e) {
          e.preventDefault();
        }
        return this._list.stop().slideUp("normal", (function(_this) {
          return function() {
            return _this._container.removeClass('open');
          };
        })(this));
      };

      return Folder;

    })();
    $.fn.slug_field = function() {
      return this.each(function() {
        return new SlugField(this);
      });
    };
    SlugField = (function() {
      function SlugField(element) {
        this.slugify = bind(this.slugify, this);
        this.set = bind(this.set, this);
        this.update = bind(this.update, this);
        var selector;
        this._field = $(element);
        this._form = this._field.parents('form');
        selector = this._field.attr('data-base') || 'input[data-role="name"]';
        this._base = this._form.find(selector);
        this._base.bind("keyup", this.update);
        this._previous_base = this._base.val();
        this.set();
      }

      SlugField.prototype.update = function(e) {
        if ($.significantKeypress(e.which)) {
          return this.set();
        }
      };

      SlugField.prototype.set = function() {
        var new_base, old_base, old_slug;
        old_base = this._previous_base;
        old_slug = this._field.val();
        new_base = this._base.val();
        if (old_slug === "" || old_slug === this.slugify(old_base)) {
          this._field.val(this.slugify(new_base));
        }
        return this._previous_base = new_base;
      };

      SlugField.prototype.slugify = function(string) {
        return string.replace(/[^\w\d]+/g, '-').toLowerCase();
      };

      return SlugField;

    })();
    $.fn.calendar = function() {
      this.each(function() {
        return new Calendar(this);
      });
      return this;
    };
    $.fn.calendar_changer = function() {
      this.click(function(e) {
        var link, month, ref, year;
        if (e) {
          e.preventDefault();
        }
        link = $(this);
        year = parseInt(link.attr('data-year'), 10);
        month = parseInt(link.attr('data-month'), 10);
        link.addClass('waiting');
        return (ref = $.calendar) != null ? ref.show(year, month) : void 0;
      });
      return this;
    };
    $.fn.calendar_search = function() {
      return this.click(function(e) {
        var ref;
        if (e) {
          e.preventDefault();
        }
        return (ref = $.calendar) != null ? ref.search($(this).text()) : void 0;
      });
    };
    ScoreShower = (function() {
      function ScoreShower(element) {
        this._container = $(element);
        this._rating = parseFloat(this._container.text(), 10);
        this._rating || (this._rating = 0);
        this._bar = $('<div class="starbar" />').appendTo(this._container);
        this._mask = $('<div class="starmask" />').appendTo(this._container);
        this._bar.css({
          width: this._rating / 5 * 80
        });
      }

      return ScoreShower;

    })();
    $.fn.star_rating = function() {
      return this.each(function() {
        return new ScoreShower(this);
      });
    };
    $.fn.sliding_link = function() {
      return this.each(function() {
        return new Slider(this);
      });
    };
    Slider = (function() {
      function Slider(element) {
        this.cleanup = bind(this.cleanup, this);
        this.sweep = bind(this.sweep, this);
        this.receive = bind(this.receive, this);
        this.defaultSelector = bind(this.defaultSelector, this);
        this.getDirection = bind(this.getDirection, this);
        this.getPage = bind(this.getPage, this);
        this._link = $(element);
        this._selector = this._link.attr('data-affected') || this.defaultSelector();
        this._direction = this.getDirection();
        this._page = this.getPage();
        this._frame = this._page.parents('.scroller').first();
        if (!this._frame.length) {
          this._page.wrap($('<div class="scroller" />'));
          this._frame = this._page.parent();
        }
        this._viewport = this._frame.parents('.scrolled').first();
        if (!this._viewport.length) {
          this._frame.wrap($('<div class="scrolled" />'));
          this._viewport = this._frame.parents('.scrolled');
        }
        this._width = this._page.width();
        this._link.remote({
          on_success: this.receive
        });
      }

      Slider.prototype.getPage = function() {
        return this._link.parents(this._selector).first();
      };

      Slider.prototype.getDirection = function() {
        return this._link.attr("data-direction");
      };

      Slider.prototype.defaultSelector = function() {
        return '.scrap';
      };

      Slider.prototype.receive = function(e, r) {
        var response;
        response = $(r);
        this.sweep(response);
        return response.activate();
      };

      Slider.prototype.sweep = function(r) {
        this._old_page = this._page;
        this._viewport.css("overflow", "hidden");
        if (this._direction === 'right') {
          this._frame.append(r);
          return this._viewport.animate({
            scrollLeft: this._width
          }, 'slow', 'glide', this.cleanup);
        } else {
          this._frame.prepend(r);
          return this._viewport.scrollLeft(this._width).animate({
            scrollLeft: 0
          }, 'slow', 'glide', this.cleanup);
        }
      };

      Slider.prototype.cleanup = function() {
        this._viewport.scrollLeft(0);
        return this._old_page.remove();
      };

      return Slider;

    })();
    $.fn.page_turner = function() {
      return this.each(function() {
        return new Pager(this);
      });
    };
    Pager = (function(superClass) {
      extend(Pager, superClass);

      function Pager(element) {
        this.getDirection = bind(this.getDirection, this);
        this.defaultSelector = bind(this.defaultSelector, this);
        Pager.__super__.constructor.apply(this, arguments);
        this._page_number = parseInt(this._link.parent().siblings('.current').text());
      }

      Pager.prototype.defaultSelector = function() {
        return '.paginated';
      };

      Pager.prototype.getDirection = function() {
        if (this._link.attr("rel")) {
          return this._direction = this._link.attr("rel") === "next" ? "right" : "left";
        } else {
          return this._direction = parseInt(this._link.text()) > this._page_number ? "right" : "left";
        }
      };

      return Pager;

    })(Slider);
    $.fn.draggable = function() {
      return this.each(function() {
        return new Draggable(this);
      });
    };
    Draggable = (function() {
      function Draggable(element) {
        this.recallPosition = bind(this.recallPosition, this);
        this.storePosition = bind(this.storePosition, this);
        this.finishDrag = bind(this.finishDrag, this);
        this.moveContainer = bind(this.moveContainer, this);
        this.startDrag = bind(this.startDrag, this);
        this.lookNormal = bind(this.lookNormal, this);
        this.lookDraggable = bind(this.lookDraggable, this);
        var selector;
        this._handle = $(element);
        selector = this._handle.data('draggable');
        if (selector && selector !== 'true' && selector !== 'draggable') {
          this._container = this._handle.parents(selector).first();
        }
        if (!this._container.length) {
          this._container = this._handle;
        }
        this._remembered = this._handle.data('remembered');
        this._handle.on("mouseenter", this.lookDraggable);
        this._handle.on("dragleave", this.lookNormal);
        this._handle.on("mousedown", this.startDrag);
        console.log("new draggable", this._remembered);
        if (this._remembered) {
          this.recallPosition();
        }
      }

      Draggable.prototype.lookDraggable = function(e) {
        return this._handle.addClass('dragme');
      };

      Draggable.prototype.lookNormal = function(e) {
        return this._handle.removeClass('dragme');
      };

      Draggable.prototype.startDrag = function(e) {
        this._container_start = this._container.offset();
        this._drag_start = {
          x: e.pageX,
          y: e.pageY
        };
        this._handle.addClass('dragging');
        this._container.addClass('dragging');
        return $(document).on("mousemove", this.moveContainer).on("mouseup", this.finishDrag);
      };

      Draggable.prototype.moveContainer = function(e) {
        var delta, newpos;
        delta = {
          x: e.pageX - this._drag_start.x,
          y: e.pageY - this._drag_start.y
        };
        newpos = {
          left: this._container_start.left + delta.x,
          top: this._container_start.top + delta.y
        };
        this._container.css(newpos);
        return newpos;
      };

      Draggable.prototype.finishDrag = function(e) {
        var adjusted_position, final_position;
        final_position = this.moveContainer(e);
        adjusted_position = {
          left: final_position.left - +window.pageXOffset,
          top: final_position.top - window.pageYOffset
        };
        $(document).off("mousemove", this.moveContainer).off("mouseup", this.finishDrag);
        if (this._remembered) {
          this.storePosition(adjusted_position);
        }
        this._container_start = null;
        this._drag_start = null;
        this._handle.removeClass('dragging');
        this._container.removeClass('dragging');
        return this._container.data('droom-positioned', adjusted_position);
      };

      Draggable.prototype.storePosition = function(position) {
        var cookie_name;
        cookie_name = "draggable_" + this._remembered;
        return $.cookie(cookie_name, JSON.stringify(position));
      };

      Draggable.prototype.recallPosition = function() {
        var cookie_name, position;
        cookie_name = "draggable_" + this._remembered;
        if (position = $.cookie(cookie_name)) {
          position = JSON.parse(position);
          this._container.css({
            left: position.left + window.pageXOffset,
            top: position.top + window.pageYOffset
          });
          return this._container.data('droom-positioned', position);
        }
      };

      return Draggable;

    })();
    Calendar = (function() {
      function Calendar(element, options) {
        this.search = bind(this.search, this);
        this.searchForMonth = bind(this.searchForMonth, this);
        this.searchForDay = bind(this.searchForDay, this);
        this.searchForm = bind(this.searchForm, this);
        this.monthName = bind(this.monthName, this);
        this.sweep = bind(this.sweep, this);
        this.update = bind(this.update, this);
        this.show = bind(this.show, this);
        this.update_quietly = bind(this.update_quietly, this);
        this.refresh_in_place = bind(this.refresh_in_place, this);
        this.cached = bind(this.cached, this);
        this.cache = bind(this.cache, this);
        this.init = bind(this.init, this);
        this._container = $(element);
        this._scroller = this._container.find('.scroller');
        this._table = null;
        this._cache = {};
        this._month = null;
        this._year = null;
        this._request = null;
        this._incoming = {};
        this._width = this._container.width();
        $.calendar = this;
        this._container.bind("refresh", this.refresh_in_place);
        this.init();
      }

      Calendar.prototype.init = function() {
        this._table = this._container.find('table');
        this._month = parseInt(this._table.attr('data-month'), 10);
        this._year = parseInt(this._table.attr('data-year'), 10);
        this.cache(this._year, this._month, this._table);
        this._table.find('a.next, a.previous').calendar_changer();
        this._table.find('a.day').click(this.searchForDay);
        return this._table.find('a.month').click(this.searchForMonth);
      };

      Calendar.prototype.cache = function(year, month, table) {
        var base, base1;
        if ((base = this._cache)[year] == null) {
          base[year] = {};
        }
        return (base1 = this._cache[year])[month] != null ? base1[month] : base1[month] = table;
      };

      Calendar.prototype.cached = function(year, month) {
        var base;
        if ((base = this._cache)[year] == null) {
          base[year] = {};
        }
        return this._cache[year][month];
      };

      Calendar.prototype.refresh_in_place = function() {
        return this._request = $.ajax({
          type: "GET",
          dataType: "html",
          url: "/events/calendar.js?month=" + (encodeURIComponent(this._month)) + "&year=" + (encodeURIComponent(this._year)),
          success: this.update_quietly
        });
      };

      Calendar.prototype.update_quietly = function(response) {
        this._container.find('a').removeClass('waiting');
        this._scroller.find('table').remove();
        this._scroller.append(response);
        return this.init();
      };

      Calendar.prototype.show = function(year, month) {
        var cached;
        if (cached = this.cached(year, month)) {
          return this.update(cached, year, month);
        } else {
          return this._request = $.ajax({
            type: "GET",
            dataType: "html",
            url: "/events/calendar.js?month=" + (encodeURIComponent(month)) + "&year=" + (encodeURIComponent(year)),
            success: (function(_this) {
              return function(response) {
                return _this.update(response, year, month);
              };
            })(this)
          });
        }
      };

      Calendar.prototype.update = function(response, year, month) {
        var direction;
        this._container.find('a').removeClass('waiting');
        if (((year * 12) + month) > ((this._year * 12) + this._month)) {
          direction = "left";
        }
        return this.sweep(response, direction);
      };

      Calendar.prototype.sweep = function(table, direction) {
        var old;
        old = this._scroller.find('table');
        if (direction === 'left') {
          this._scroller.append(table);
          return this._container.animate({
            scrollLeft: this._width
          }, 'fast', (function(_this) {
            return function() {
              old.remove();
              _this._container.scrollLeft(0);
              return _this.init();
            };
          })(this));
        } else {
          this._scroller.prepend(table);
          return this._container.scrollLeft(this._width).animate({
            scrollLeft: 0
          }, 'fast', (function(_this) {
            return function() {
              old.remove();
              return _this.init();
            };
          })(this));
        }
      };

      Calendar.prototype.monthName = function() {
        var months;
        months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return months[this._month - 1];
      };

      Calendar.prototype.searchForm = function() {
        return this._form != null ? this._form : this._form = $('#suggestions');
      };

      Calendar.prototype.searchForDay = function(e) {
        var day;
        if (e) {
          e.preventDefault();
        }
        day = $(e.target).text();
        return this.search(day + " " + (this.monthName()) + " " + this._year);
      };

      Calendar.prototype.searchForMonth = function(e) {
        if (e) {
          e.preventDefault();
        }
        return this.search((this.monthName()) + " " + this._year);
      };

      Calendar.prototype.search = function(term) {
        var ref;
        if ((ref = this.searchForm()) != null) {
          ref.find('input#term').val(term).change();
        }
        return this.searchForm().trigger('show');
      };

      return Calendar;

    })();
    $.fn.suggestible = function(options) {
      options = $.extend({
        submit_form: true,
        threshold: 3
      }, options);
      this.each(function() {
        return new Suggester(this, options);
      });
      return this;
    };
    $.fn.venue_picker = function(options) {
      options = $.extend({
        submit_form: false,
        threshold: 1,
        type: 'venue',
        width: 300
      }, options);
      this.each(function() {
        return new Suggester(this, options);
      });
      return this;
    };
    $.fn.person_selector = function(options) {
      options = $.extend({
        submit_form: false,
        threshold: 1,
        type: 'person'
      }, options);
      this.each(function() {
        var suggester, target;
        target = $(this).siblings('.person_picker_target');
        $(this).bind("keyup", (function(_this) {
          return function() {
            return target.val(null);
          };
        })(this));
        suggester = new Suggester(this, options);
        return suggester.options.afterSelect = function(value, id) {
          return target.val(id);
        };
      });
      return this;
    };
    $.fn.person_picker = function(options) {
      options = $.extend({
        submit_form: false,
        threshold: 1,
        type: 'person'
      }, options);
      this.each(function() {
        var suggester, target;
        target = $(this).siblings('.person_picker_target');
        $(this).bind("keyup", (function(_this) {
          return function() {
            return target.val(null);
          };
        })(this));
        suggester = new Suggester(this, options);
        return suggester.options.afterSelect = function() {
          var id;
          id = JSON.parse(suggester.request.responseText)[0].id;
          target.val(id);
          return suggester.form.submit();
        };
      });
      return this;
    };
    $.fn.group_picker = function(options) {
      options = $.extend({
        submit_form: true,
        threshold: 1,
        type: 'group'
      }, options);
      this.each(function() {
        var suggester, target;
        target = $(this).siblings('.group_picker_target');
        $(this).bind("keyup", (function(_this) {
          return function() {
            return target.val(null);
          };
        })(this));
        suggester = new Suggester(this, options);
        return suggester.options.afterSelect = function() {
          var id;
          id = JSON.parse(suggester.request.responseText)[0].id;
          target.val(id);
          return suggester.form.submit();
        };
      });
      return this;
    };
    $.fn.application_suggester = function(options) {
      options = $.extend({
        submit_form: false,
        threshold: 1,
        limit: 5,
        type: 'application'
      }, options);
      this.each(function() {
        return new Suggester(this, options);
      });
      return this;
    };
    Suggester = (function() {
      function Suggester(element, options) {
        this.unwait = bind(this.unwait, this);
        this.wait = bind(this.wait, this);
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.select = bind(this.select, this);
        this.suggest = bind(this.suggest, this);
        this.previously_blank = bind(this.previously_blank, this);
        this.get = bind(this.get, this);
        this.reset = bind(this.reset, this);
        var base, base1;
        this.prompt = $(element);
        this.type = this.prompt.attr('data-type');
        this.form = this.prompt.parents("form");
        this.options = $.extend({
          fill_field: true,
          empty_field: false,
          submit_form: false,
          preload: false,
          width: "auto",
          threshold: 2,
          limit: 10,
          afterSuggest: null,
          afterSelect: null
        }, options);
        if (options.type) {
          if ((base = this.options).url == null) {
            base.url = "/suggestions/" + options.type + ".json";
          }
        } else {
          if ((base1 = this.options).url == null) {
            base1.url = "/suggestions.json";
          }
        }
        if (this.options.preload) {
          this.options.url += "?empty=all";
        }
        this.dropdown = new Dropdown(this.prompt, {
          on_select: this.select,
          on_keyup: this.get,
          width: this.options.width
        });
        this.button = this.form.find("a.search");
        this.previously = null;
        this.request = null;
        this.visible = false;
        this.suggestions = [];
        this.suggestion = null;
        this.cache = {};
        this.blanks = [];
        this.prompt.bind("blur", this.hide);
        this.prompt.bind("paste", this.get);
        this.form.submit(this.hide);
        if (this.options.preload) {
          this.get(null, true);
        }
        this;
      }

      Suggester.prototype.reset = function() {
        return this.dropdown.reset().hide();
      };

      Suggester.prototype.get = function(e, force) {
        var query;
        this.wait();
        query = this.prompt.val();
        if (force || query.length >= this.options.threshold && query !== this.previously) {
          if (this.cache[query]) {
            return this.suggest(this.cache[query]);
          } else if (this.previously_blank(query)) {
            return this.suggest([]);
          } else {
            if (this.request) {
              this.request.abort();
            }
            return this.request = $.getJSON(this.options.url, "term=" + encodeURIComponent(query) + "&limit=" + this.options.limit, (function(_this) {
              return function(suggestions) {
                _this.cache[query] = suggestions;
                if (suggestions.length === 0) {
                  _this.blanks.push(query);
                }
                return _this.suggest(suggestions);
              };
            })(this));
          }
        } else {
          return this.hide();
        }
      };

      Suggester.prototype.previously_blank = function(query) {
        var blank_re;
        if (this.blanks.length > 0) {
          blank_re = new RegExp("(" + this.blanks.join("|") + ")");
          return blank_re.test(query);
        }
        return false;
      };

      Suggester.prototype.suggest = function(suggestions) {
        this.unwait();
        this.dropdown.show(suggestions);
        if (this.options.afterSuggest) {
          return this.options.afterSuggest.call(this, suggestions);
        }
      };

      Suggester.prototype.select = function(value, id) {
        if (this.options.fill_field != null) {
          this.prompt.val(value);
          this.prompt.trigger('suggester.change');
        } else if (this.options.empty_field != null) {
          this.prompt.val("");
        }
        if (this.options.afterSelect) {
          return this.options.afterSelect.call(this, value);
        }
      };

      Suggester.prototype.show = function() {
        return this.dropdown.show();
      };

      Suggester.prototype.hide = function() {
        return this.dropdown.hide();
      };

      Suggester.prototype.wait = function() {
        this.button.addClass("waiting");
        return this.prompt.addClass("waiting");
      };

      Suggester.prototype.unwait = function() {
        this.button.removeClass("waiting");
        return this.prompt.removeClass("waiting");
      };

      return Suggester;

    })();
    $.fn.youtube_suggester = function(options) {
      options = $.extend({
        submit_form: true,
        threshold: 3,
        type: "video",
        url: "/videos.json"
      }, options);
      this.each(function() {
        return new YoutubeSuggester(this, options);
      });
      return this;
    };
    YoutubeSuggester = (function(superClass) {
      extend(YoutubeSuggester, superClass);

      function YoutubeSuggester() {
        this.get_thumbnail = bind(this.get_thumbnail, this);
        this.show_preview = bind(this.show_preview, this);
        this.get_preview = bind(this.get_preview, this);
        this.select = bind(this.select, this);
        this.suggest = bind(this.suggest, this);
        YoutubeSuggester.__super__.constructor.apply(this, arguments);
        this.target = $('input#scrap_youtube_id');
        this.name_field = $('input#scrap_name');
        this.preview_holder = $('div.youtube_preview');
        this.thumb_holder = this.prompt.siblings('.thumbnail');
      }

      YoutubeSuggester.prototype.suggest = function(suggestions) {
        var detailed_suggestions;
        this.unwait();
        if (suggestions.length > 0) {
          detailed_suggestions = $.map(suggestions, function(suggestion, i) {
            var ref, ref1;
            return {
              type: "video",
              id: suggestion.unique_id,
              value: "<img src='" + suggestion.thumbnails[0].url + "' /><span class=\"title\">" + ((ref = suggestion.title) != null ? ref.truncate(36) : void 0) + "</span><br /><span class=\"description\">" + ((ref1 = suggestion.description) != null ? ref1.truncate(48) : void 0) + "</span>"
            };
          });
          this.dropdown.show(detailed_suggestions);
        } else {
          this.hide();
        }
        if (this.options.afterSuggest) {
          return this.options.afterSuggest.call(this, suggestions);
        }
      };

      YoutubeSuggester.prototype.select = function(value, id) {
        var ref, title;
        this.hide();
        this.prompt.trigger('suggester.change');
        this.prompt.val(id);
        title = $("<div>" + value + "</div>").find('.title');
        if (this.name_field.val() === "") {
          this.name_field.val(title.text());
        }
        this.get_preview(id);
        this.get_thumbnail(id);
        return (ref = this.options.afterSelect) != null ? ref.call(this, value) : void 0;
      };

      YoutubeSuggester.prototype.get_preview = function(id) {
        return $.get("/videos/" + id + ".js", this.show_preview, 'html');
      };

      YoutubeSuggester.prototype.show_preview = function(response) {
        return this.preview_holder.empty().show().html(response);
      };

      YoutubeSuggester.prototype.get_thumbnail = function(id) {
        return this.thumb_holder.css({
          "background-image": "url('http://img.youtube.com/vi/" + id + "/3.jpg')"
        });
      };

      return YoutubeSuggester;

    })(Suggester);
    $.fn.dropdown = function(options) {
      return this.each(function() {
        return new Dropdown(this, options);
      });
    };
    return Dropdown = (function() {
      function Dropdown(element, opts) {
        this.unHighlight = bind(this.unHighlight, this);
        this.highlight = bind(this.highlight, this);
        this.hover = bind(this.hover, this);
        this.last = bind(this.last, this);
        this.first = bind(this.first, this);
        this.previous = bind(this.previous, this);
        this.next = bind(this.next, this);
        this.match = bind(this.match, this);
        this.movementKey = bind(this.movementKey, this);
        this.keyup = bind(this.keyup, this);
        this.actionKey = bind(this.actionKey, this);
        this.keydown = bind(this.keydown, this);
        this.hide = bind(this.hide, this);
        this.show = bind(this.show, this);
        this.cancel = bind(this.cancel, this);
        this.select = bind(this.select, this);
        this.select_highlit = bind(this.select_highlit, this);
        this.reset = bind(this.reset, this);
        this.populate = bind(this.populate, this);
        this.place = bind(this.place, this);
        this.hook = $(element);
        this.drop = $('<ul class="dropdown" />').insertAfter(this.hook).hide();
        this.options = $.extend({}, opts);
        this.hook.bind("keydown", this.keydown);
        this.hook.bind("keyup", this.keyup);
        this;
      }

      Dropdown.prototype.place = function() {
        var width;
        if (!(width = this.options.width)) {
          width = this.hook.outerWidth() - 2;
        }
        return this.drop.css({
          top: this.hook.position().top + this.hook.outerHeight() - 2,
          left: this.hook.position().left,
          width: width
        });
      };

      Dropdown.prototype.populate = function(items) {
        this.reset();
        if (items.length > 0) {
          $.each(items, (function(_this) {
            return function(i, item) {
              var id, link, ref, ref1, ref2, ref3, ref4, value;
              id = (ref = (ref1 = item.id) != null ? ref1 : item.value) != null ? ref : item.unique_id;
              value = (ref2 = (ref3 = (ref4 = item.title) != null ? ref4 : item.value) != null ? ref3 : item.prompt) != null ? ref2 : item.id;
              link = $("<a href=\"#\">" + value + "</a>");
              link.hover(function() {
                _this.hover(link);
                return link.click(function(e) {
                  e.preventDefault();
                  e.stopPropagation();
                  _this.item = i;
                  return _this.select(value, id);
                });
              });
              return $("<li></li>").addClass(item.type).append(link).appendTo(_this.drop);
            };
          })(this));
        }
        return this.items = this.drop.find("a");
      };

      Dropdown.prototype.reset = function() {
        return this.drop.empty();
      };

      Dropdown.prototype.select_highlit = function(e) {
        var highlit;
        if (highlit = this.items[this.item]) {
          e.preventDefault();
          e.stopPropagation();
          return this.select($(highlit).text());
        }
      };

      Dropdown.prototype.select = function(value, id) {
        var base;
        this.hide();
        return typeof (base = this.options).on_select === "function" ? base.on_select(value, id) : void 0;
      };

      Dropdown.prototype.cancel = function(e) {
        var base;
        this.hide();
        return typeof (base = this.options).on_cancel === "function" ? base.on_cancel() : void 0;
      };

      Dropdown.prototype.show = function(values) {
        this.place();
        if (values) {
          this.populate(values);
        }
        if (!this.visible) {
          this.drop.stop().fadeIn("fast");
          return this.visible = true;
        }
      };

      Dropdown.prototype.hide = function() {
        if (this.visible) {
          this.drop.stop().fadeOut("fast");
          return this.visible = false;
        }
      };

      Dropdown.prototype.keydown = function(e) {
        var action, base, kc, ref;
        kc = e.which;
        if (action = this.actionKey(kc)) {
          if ((ref = this.items) != null ? ref.length : void 0) {
            action.call(this, e);
          }
          return true;
        } else {
          if (typeof (base = this.options).on_keydown === "function") {
            base.on_keydown(e);
          }
          return true;
        }
      };

      Dropdown.prototype.actionKey = function(kc) {
        switch (kc) {
          case 27:
            return this.hide;
          case 13:
            return this.select_highlit;
        }
      };

      Dropdown.prototype.keyup = function(e, discard) {
        var action, base, kc, ref;
        kc = e.which;
        if (action = this.movementKey(kc)) {
          if ((ref = this.items) != null ? ref.length : void 0) {
            this.show();
          }
          if (this.visible) {
            action.call(this, e);
          }
          return true;
        } else {
          if (typeof (base = this.options).on_keyup === "function") {
            base.on_keyup(e);
          }
          return true;
        }
      };

      Dropdown.prototype.movementKey = function(kc) {
        switch (kc) {
          case 33:
            return this.first;
          case 38:
            return this.previous;
          case 40:
            return this.next;
          case 34:
            return this.last;
        }
      };

      Dropdown.prototype.match = function(text) {
        var holder, item, matching, top;
        matching = this.items.filter(":contains(" + text + ")");
        $.items = this.items;
        if (item = matching.first()) {
          this.hover(item);
          if (holder = item.parents('li').first()) {
            top = holder.offset().top;
            return this.drop.scrollTop(top);
          }
        }
      };

      Dropdown.prototype.next = function(e) {
        if ((this.item == null) || this.item >= this.items.length - 1) {
          return this.first();
        } else {
          return this.highlight(this.item + 1);
        }
      };

      Dropdown.prototype.previous = function(e) {
        if (this.item <= 0) {
          return this.last();
        } else {
          return this.highlight(this.item - 1);
        }
      };

      Dropdown.prototype.first = function(e) {
        return this.highlight(0);
      };

      Dropdown.prototype.last = function(e) {
        return this.highlight(this.items.length - 1);
      };

      Dropdown.prototype.hover = function(link) {
        return this.highlight(this.items.index(link));
      };

      Dropdown.prototype.highlight = function(i) {
        if (this.item !== null) {
          this.unHighlight(this.item);
        }
        $(this.items.get(i)).addClass("hover");
        return this.item = i;
      };

      Dropdown.prototype.unHighlight = function(i) {
        var item, ref;
        if (item = (ref = this.items) != null ? ref.get(i) : void 0) {
          return $(item).removeClass("hover");
        }
      };

      return Dropdown;

    })();
  });

}).call(this);