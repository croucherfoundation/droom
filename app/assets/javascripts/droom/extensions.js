(function() {
  if (Array.prototype.last == null) {
    Array.prototype.last = function() {
      return this[this.length - 1];
    };
  }

  if (Array.prototype.first == null) {
    Array.prototype.first = function() {
      return this[0];
    };
  }

  if (Array.prototype.max == null) {
    Array.prototype.max = function() {
      return Math.max.apply(Math, this);
    };
  }

  if (Array.prototype.min == null) {
    Array.prototype.min = function() {
      return Math.min.apply(Math, this);
    };
  }

  if (Array.prototype.any == null) {
    Array.prototype.any = function() {
      return this.length > 0;
    };
  }

  if (Array.prototype.empty == null) {
    Array.prototype.empty = function() {
      return this.length === 0;
    };
  }

  if (Array.prototype.contains == null) {
    Array.prototype.contains = function(thing) {
      return this.indexOf(thing) !== -1;
    };
  }

  if (Array.prototype.indexOf == null) {
    Array.prototype.indexOf = function(elt) {
      var i, item, j, len, ref;
      ref = this;
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        item = ref[i];
        if (item === elt) {
          return i;
        }
      }
      return -1;
    };
  }

  if (Array.prototype.remove == null) {
    Array.prototype.remove = function(thing) {
      return this.splice(this.indexOf(thing), 1);
    };
  }

  if (Array.prototype.toSentence == null) {
    Array.prototype.toSentence = function() {
      return this.join(", ").replace(/,\s([^,]+)$/, ' and $1');
    };
  }

  if (String.prototype.truncate == null) {
    String.prototype.truncate = function(length, separator, ellipsis) {
      var trimmed;
      if (length == null) {
        length = 100;
      }
      if (ellipsis == null) {
        ellipsis = '...';
      }
      if (this.length > length) {
        trimmed = this.substr(0, length - ellipsis.length);
        if (separator != null) {
          trimmed = trimmed.substr(0, trimmed.lastIndexOf(separator));
        }
        return trimmed + '...';
      } else {
        return this;
      }
    };
  }

  if (String.prototype.trim == null) {
    String.prototype.trim = function(length, separator, ellipsis) {
      return String(this).replace(/^\s+|\s+$/g, '');
    };
  }

}).call(this);