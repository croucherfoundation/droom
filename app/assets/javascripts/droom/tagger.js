(function() {
  var TagChooser, TagFaceter, Tagger,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  $.fn.tagger = function() {
    return this.each(function() {
      return new TagChooser(this);
    });
  };

  $.fn.faceter = function() {
    return this.each(function() {
      return new TagFaceter(this);
    });
  };

  Tagger = (function() {
    function Tagger(el) {
      this.changed = bind(this.changed, this);
      this.accept = bind(this.accept, this);
      this.focus = bind(this.focus, this);
      var existing_terms, value;
      this._el = $(el);
      this._field = this._el.find('input.tags');
      this._form = this._field.parents('form');
      if (value = this._field.val()) {
        existing_terms = _.map(_.uniq(value.split(',')), function(term) {
          return {
            name: term
          };
        });
      } else {
        existing_terms = [];
      }
      this._field.tokenInput("/api/tags", {
        minChars: 2,
        excludeCurrent: true,
        allowFreeTagging: true,
        zindex: 9000,
        tokenValue: "name",
        prePopulate: existing_terms,
        hintText: "Type in a search term to see suggestions. Enter creates a new tag.",
        onResult: (function(_this) {
          return function(data) {
            var seen, terms;
            seen = {};
            terms = [];
            _.map(data, function(suggestion) {
              if (!seen[suggestion.name]) {
                terms.push({
                  name: suggestion.name
                });
                return seen[suggestion.name] = true;
              }
            });
            return terms;
          };
        })(this)
      });
      this._search_field = this._el.find('li.token-input-input-token input[type="text"]');
      this._search_field.attr("placeholder", this._field.attr('placeholder'));
      this._field.on("change", this.changed);
      if (this._el.hasClass('active')) {
        this.focus();
      }
    }

    Tagger.prototype.focus = function() {
      return this._search_field.focus();
    };

    Tagger.prototype.accept = function() {};

    Tagger.prototype.changed = function() {};

    return Tagger;

  })();

  TagChooser = (function(superClass) {
    extend(TagChooser, superClass);

    function TagChooser() {
      this.accept = bind(this.accept, this);
      return TagChooser.__super__.constructor.apply(this, arguments);
    }

    TagChooser.prototype.accept = function() {
      this._field.tokenInput("add", {
        name: this._current_tag
      });
      this._search_field.val("");
      return this.observeSearch();
    };

    return TagChooser;

  })(Tagger);

  TagFaceter = (function(superClass) {
    extend(TagFaceter, superClass);

    function TagFaceter() {
      this.close = bind(this.close, this);
      this.changed = bind(this.changed, this);
      return TagFaceter.__super__.constructor.apply(this, arguments);
    }

    TagFaceter.prototype.changed = function() {
      this._el.addClass('waiting');
      return this._form.submit();
    };

    TagFaceter.prototype.close = function() {
      this._field.tokenInput('clear');
      this._el.removeClass('active');
      return this.changed();
    };

    return TagFaceter;

  })(Tagger);

}).call(this);