(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  jQuery(function($) {
    var Remote;
    $.fn.remote = function(opts) {
      return this.each(function() {
        return new Remote(this, opts);
      });
    };
    return Remote = (function() {
      function Remote(element, opts) {
        this.cancel = bind(this.cancel, this);
        this.receive = bind(this.receive, this);
        this.fail = bind(this.fail, this);
        this.progress = bind(this.progress, this);
        this.gotFiles = bind(this.gotFiles, this);
        this.pend = bind(this.pend, this);
        this.activate = bind(this.activate, this);
        this._control = $(element);
        this._options = $.extend({}, opts);
        this._control.attr('data-remote', true);
        this._control.attr('data-type', 'html');
        this._fily = false;
        this._control.on('ajax:beforeSend', this.pend);
        this._control.on('ajax:error', this.fail);
        this._control.on('ajax:success', this.receive);
        this._control.on('ajax:filedata', this.gotFiles);
        this._control.on('ajax:progress', this.progress);
        this._control.on('remote:prepare', this._options.on_prepare);
        this._control.on('remote:progress', this._options.on_progress);
        this._control.on('remote:error', this._options.on_error);
        this._control.on('remote:success', this._options.on_success);
        this._control.on('remote:complete', this._options.on_complete);
        this._control.on('remote:cancel', this._options.on_cancel);
        this.activate();
      }

      Remote.prototype.activate = function() {
        this._control.find('a.cancel').click(this.cancel);
        return this._control.trigger('remote:prepare');
      };

      Remote.prototype.pend = function(event, xhr, settings) {
        var base, ref;
        event.stopPropagation();
        event.preventDefault();
        xhr.setRequestHeader('X-PJAX', 'true');
        this._control.addClass('waiting');
        this._control.find('input[type=submit]').addClass('waiting');
        return (ref = typeof (base = this._options).on_request === "function" ? base.on_request(xhr, settings) : void 0) != null ? ref : true;
      };

      Remote.prototype.gotFiles = function(event, elements) {
        this._control.trigger('remote:upload');
        return true;
      };

      Remote.prototype.progress = function(e, prog) {
        return this._control.trigger("remote:progress", prog);
      };

      Remote.prototype.fail = function(event, xhr, status) {
        var ref;
        if (xhr.status === 409) {
          if ((ref = $(event.currentTarget).find('p.error')) != null) {
            ref.text(xhr.responseText);
          }
          $('input[type="submit"]').css("background-color", "#9b9b8e");
        }
        if (xhr.status === 401) {
          window.location.reload();
        }
        event.stopPropagation();
        this._control.removeClass('waiting').addClass('erratic');
        this._control.find('input[type=submit]').removeClass('waiting');
        this._control.trigger('remote:error', xhr, status);
        return this._control.trigger('remote:complete', status);
      };

      Remote.prototype.receive = function(event, data, status, xhr) {
        event.stopPropagation();
        this._control.removeClass('waiting');
        this._control.trigger('remote:success', data);
        return this._control.trigger('remote:complete', status);
      };

      Remote.prototype.cancel = function(e) {
        var ref;
        if (e) {
          e.preventDefault();
        }
        this._control.trigger('remote:cancel');
        return (ref = this._form) != null ? ref.remove() : void 0;
      };

      return Remote;

    })();
  });

}).call(this);