(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  Ed.Model = (function(superClass) {
    extend(Model, superClass);

    function Model() {
      this.isDestroyed = bind(this.isDestroyed, this);
      this.touch = bind(this.touch, this);
      this.remove = bind(this.remove, this);
      this.finishProgress = bind(this.finishProgress, this);
      this.setProgress = bind(this.setProgress, this);
      this.startProgress = bind(this.startProgress, this);
      this.revert = bind(this.revert, this);
      this.toJSON = bind(this.toJSON, this);
      this.clearTemporaryAttributes = bind(this.clearTemporaryAttributes, this);
      this.resetOriginalAttributes = bind(this.resetOriginalAttributes, this);
      this.significantChangedAttributes = bind(this.significantChangedAttributes, this);
      this.changedIfSignificant = bind(this.changedIfSignificant, this);
      this.saveIfChanged = bind(this.saveIfChanged, this);
      this.apiRoot = bind(this.apiRoot, this);
      this.readDates = bind(this.readDates, this);
      this.parse = bind(this.parse, this);
      this.has = bind(this.has, this);
      this.build = bind(this.build, this);
      return Model.__super__.constructor.apply(this, arguments);
    }

    Model.prototype.savedAttributes = [];

    Model.prototype.initialize = function() {
      this._loaded = $.Deferred();
      this.build();
      this.resetOriginalAttributes();
      this.on('sync', this.resetOriginalAttributes);
      return this.on("change", this.changedIfSignificant);
    };

    Model.prototype.build = function() {};

    Model.prototype.has = function(attribute) {
      return !!this.get(attribute);
    };

    Model.prototype.parse = function(data) {
      this.readDates(data);
      return data;
    };

    Model.prototype.readDates = function(data) {
      var col, i, len, ref, results, string;
      ref = ["created_at", "updated_at", "published_at", "deleted_at"];
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        col = ref[i];
        if (string = data[col]) {
          this.set(col, new Date(string));
          results.push(delete data[col]);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Model.prototype.apiRoot = function() {
      return this.constructor.name.toLowerCase();
    };

    Model.prototype.saveIfChanged = function() {
      if (this.get('changed')) {
        return this.save();
      }
    };

    Model.prototype.changedIfSignificant = function() {
      return this.set("changed", !_.isEmpty(this.significantChangedAttributes()));
    };

    Model.prototype.significantChangedAttributes = function() {
      var changed_keys;
      changed_keys = _.filter(this.savedAttributes, (function(_this) {
        return function(k) {
          return !_.isEqual(_this.get(k), _this._original_attributes[k]);
        };
      })(this));
      return _.pick(this.attributes, changed_keys);
    };

    Model.prototype.resetOriginalAttributes = function() {
      this._original_attributes = _.pick(this.attributes, this.savedAttributes);
      return this.set('changed', false);
    };

    Model.prototype.clearTemporaryAttributes = function() {};

    Model.prototype.toJSON = function() {
      var att, attributes, getter, i, json, len, ref, root;
      root = this.apiRoot();
      json = {};
      json[root] = {};
      this.log("savedAttributes", root, _.result(this, "savedAttributes"));
      if (attributes = _.result(this, "savedAttributes")) {
        for (i = 0, len = attributes.length; i < len; i++) {
          att = attributes[i];
          getter = "get" + att.charAt(0).toUpperCase() + att.slice(1);
          json[root][att] = (ref = typeof this[getter] === "function" ? this[getter]() : void 0) != null ? ref : this.get(att);
        }
      } else {
        json[root] = Model.__super__.toJSON.apply(this, arguments);
      }
      this.log("-> json", json);
      return json;
    };

    Model.prototype.revert = function() {
      return this.set(this._original_attributes);
    };

    Model.prototype.startProgress = function(label) {
      if (label == null) {
        label = "";
      }
      this.set("progress", 0.00);
      this.set("progressing", true);
      this.set("progress_label", label);
      if (_ed.model) {
        return this._job = _ed.model.startJob(label + " " + this.constructor.name);
      } else {
        return this._job = new Ed.Models.Job(label + " " + this.constructor.name);
      }
    };

    Model.prototype.setProgress = function(p) {
      var progress;
      if (p.lengthComputable) {
        progress = p.loaded / p.total;
        return this.set("progress", progress.toFixed(2));
      }
    };

    Model.prototype.finishProgress = function() {
      var ref;
      this.set("progress", 2.00);
      this.set("progressing", false);
      this.set("progress_label", "");
      if ((ref = this._job) != null) {
        ref.finish();
      }
      return this._job = null;
    };

    Model.prototype.remove = function() {
      var ref;
      return (ref = this.collection) != null ? ref.remove(this) : void 0;
    };

    Model.prototype.touch = function() {
      return this.set('updated_at', moment(), {
        stickitChange: true
      });
    };

    Model.prototype.isDestroyed = function() {
      return this.get('deleted_at');
    };

    Model.prototype.log = function() {
      return _ed.log.apply(_ed, ["[" + this.constructor.name + "]"].concat(slice.call(arguments)));
    };

    Model.prototype.confirm = function() {
      return _ed.confirm.apply(_ed, arguments);
    };

    Model.prototype.complain = function() {
      return _ed.complain.apply(_ed, arguments);
    };

    return Model;

  })(Backbone.Model);

  Ed.Collection = (function(superClass) {
    extend(Collection, superClass);

    function Collection() {
      return Collection.__super__.constructor.apply(this, arguments);
    }

    Collection.prototype.log = function() {
      return _ed.log.apply(_ed, ["[" + this.constructor.name + "]"].concat(slice.call(arguments)));
    };

    Collection.prototype.confirm = function() {
      return _ed.confirm.apply(_ed, arguments);
    };

    Collection.prototype.complain = function() {
      return _ed.complain.apply(_ed, arguments);
    };

    return Collection;

  })(Backbone.Collection);

  Ed.Models.Editable = (function(superClass) {
    extend(Editable, superClass);

    function Editable() {
      this.textContent = bind(this.textContent, this);
      this.cleanContent = bind(this.cleanContent, this);
      this.contentWrapper = bind(this.contentWrapper, this);
      this.slugify = bind(this.slugify, this);
      this.setSlug = bind(this.setSlug, this);
      this.setImageId = bind(this.setImageId, this);
      this.setImage = bind(this.setImage, this);
      this.setBusyness = bind(this.setBusyness, this);
      this.startJob = bind(this.startJob, this);
      this.build = bind(this.build, this);
      return Editable.__super__.constructor.apply(this, arguments);
    }

    Editable.prototype.defaults = {
      title: "",
      intro: "",
      slug: "",
      main_image_id: null,
      content: "<p></p>"
    };

    Editable.prototype.build = function() {
      this._jobs = new Ed.Collections.Jobs;
      this._jobs.on("add remove reset", this.setBusyness);
      return this.on("change:title", this.setSlug);
    };

    Editable.prototype.startJob = function(label) {
      var job;
      job = this._jobs.add({
        label: label
      });
      window.job = job;
      job.on("finished", (function(_this) {
        return function() {
          return _this._jobs.remove(job);
        };
      })(this));
      return job;
    };

    Editable.prototype.setBusyness = function() {
      return this.set('busy', !!this._jobs.length);
    };

    Editable.prototype.setImage = function(image) {
      console.log("setImage", image);
      if (image) {
        this.set("main_image", image);
        if (image.id) {
          return this.setImageId(image);
        } else {
          return image.once('sync', (function(_this) {
            return function() {
              return _this.setImageId(image);
            };
          })(this));
        }
      } else {
        return this.setImageId(null);
      }
    };

    Editable.prototype.setImageId = function(image) {
      console.log("setImage", image != null ? image.id : void 0);
      return this.set('main_image_id', image != null ? image.id : void 0);
    };

    Editable.prototype.setSlug = function() {
      var slug, title;
      title = this.get('title');
      slug = this.get('slug');
      if (!slug || slug === this.slugify(this.previous('title'))) {
        return this.set('slug', this.slugify(title));
      }
    };

    Editable.prototype.slugify = function(html) {
      var from_chars, regex, spaced_html, str, to_chars;
      spaced_html = html.replace(/(&nbsp;|<br>)/g, ' ');
      str = $('<div />').html(spaced_html).text().trim();
      from_chars = "ąàáäâãåæćęęèéëêìíïîłńòóöôõøśùúüûñçżź";
      to_chars = "aaaaaaaaceeeeeeiiiilnoooooosuuuunczz";
      regex = new RegExp('[' + from_chars.replace(/([.*+?^=!:${}()|[\]\/\\])/g, '\\$1') + ']', 'g');
      if (!str) {
        return '';
      }
      str = String(str).toLowerCase().replace(regex, function(c) {
        return to_chars.charAt(from_chars.indexOf(c)) || '-';
      });
      return str.replace(/[^\w\s-]/g, '').replace(/([A-Z])/g, '-$1').replace(/[-_\s]+/g, '-').toLowerCase();
    };

    Editable.prototype.contentWrapper = function() {
      var content, wrapper;
      wrapper = $('<div />');
      if (content = this.get('content')) {
        wrapper.html(content.trim());
        wrapper.find('[contenteditable], [contenteditable="false"]').removeAttr('contenteditable');
        wrapper.find('[data-placeholder]').removeAttr('data-placeholder');
        wrapper.find('.medium-editor-element').removeClass('medium-editor-element');
        wrapper.find('.ed-button').remove();
        wrapper.find('.ed-buttons').remove();
        wrapper.find('.ed-progress').remove();
        wrapper.find('.ed-action').remove();
        wrapper.find('.ed-dropmask').remove();
      }
      return wrapper;
    };

    Editable.prototype.cleanContent = function() {
      return this.contentWrapper().html();
    };

    Editable.prototype.textContent = function() {
      return this.contentWrapper().text();
    };

    return Editable;

  })(Ed.Model);

  Ed.Models.Block = (function(superClass) {
    extend(Block, superClass);

    function Block() {
      return Block.__super__.constructor.apply(this, arguments);
    }

    Block.prototype.defaults = {
      content: ""
    };

    return Block;

  })(Ed.Model);

  Ed.Collections.Blocks = (function(superClass) {
    extend(Blocks, superClass);

    function Blocks() {
      return Blocks.__super__.constructor.apply(this, arguments);
    }

    Blocks.prototype.model = Ed.Models.Block;

    return Blocks;

  })(Backbone.Collection);

  Ed.Models.Image = (function(superClass) {
    extend(Image, superClass);

    function Image() {
      this.extractImage = bind(this.extractImage, this);
      this.getThumbs = bind(this.getThumbs, this);
      this.build = bind(this.build, this);
      return Image.__super__.constructor.apply(this, arguments);
    }

    Image.prototype.savedAttributes = ["file_data", "file_name", "remote_url", "caption"];

    Image.prototype.defaults = {
      url: "",
      hero_url: "",
      full_url: "",
      half_url: "",
      icon_url: "",
      caption: ""
    };

    Image.prototype.build = function() {
      this.on('change:file_data', this.getThumbs);
      return this.getThumbs();
    };

    Image.prototype.getThumbs = function() {
      var img;
      window.nim = this;
      if (this.has('file_data') && !this.has('url')) {
        img = document.createElement('img');
        img.onload = (function(_this) {
          return function() {
            _this.set('icon_url', _this.extractImage(img, 64));
            _this.set('half_url', _this.extractImage(img, 320));
            _this.set('full_url', _this.extractImage(img, 640));
            _this.set('hero_url', _this.get('full_url'));
            return _this.set('url', _this.get('full_url'));
          };
        })(this);
        return img.src = this.get('file_data');
      }
    };

    Image.prototype.extractImage = function(img, w) {
      var canvas, ctx, h;
      if (w == null) {
        w = 64;
      }
      if (img.height > img.width) {
        h = w * (img.height / img.width);
      } else {
        h = w;
        w = h * (img.width / img.height);
      }
      canvas = document.createElement('canvas');
      canvas.width = w;
      canvas.height = h;
      ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, w, h);
      return canvas.toDataURL('image/png');
    };

    return Image;

  })(Ed.Model);

  Ed.Collections.Images = (function(superClass) {
    extend(Images, superClass);

    function Images() {
      return Images.__super__.constructor.apply(this, arguments);
    }

    Images.prototype.model = Ed.Models.Image;

    Images.prototype.url = "/api/images";

    return Images;

  })(Ed.Collection);

  Ed.Models.Video = (function(superClass) {
    extend(Video, superClass);

    function Video() {
      this.extractImage = bind(this.extractImage, this);
      this.getVideo = bind(this.getVideo, this);
      this.build = bind(this.build, this);
      return Video.__super__.constructor.apply(this, arguments);
    }

    Video.prototype.savedAttributes = ["file", "file_name", "remote_url", "caption"];

    Video.prototype.defaults = {
      url: "",
      full_url: "",
      half_url: "",
      icon_url: ""
    };

    Video.prototype.build = function() {
      this.on('change:file_data', this.getVideo);
      return this.getVideo();
    };

    Video.prototype.getVideo = function() {
      var vid;
      if (!this.has('thumb_url')) {
        vid = document.createElement('video');
        vid.onloadeddata = (function(_this) {
          return function() {
            _this.set('icon_url', _this.extractImage(vid, 64, 10));
            _this.set('half_url', _this.extractImage(vid, 540, 10));
            _this.set('full_url', _this.extractImage(vid, 1120, 10));
            return _this.set('url', _this.get('full_url'));
          };
        })(this);
        return vid.src = this.get('file_data');
      }
    };

    Video.prototype.extractImage = function(vid, w, t) {
      var canvas, ctx, h;
      if (w == null) {
        w = 48;
      }
      if (t == null) {
        t = 0;
      }
      if (!this.get('poster_url')) {
        if (vid.videoHeight > vid.videoWidth) {
          h = w * (vid.videoHeight / vid.videoWidth);
        } else {
          h = w;
          w = h * (vid.videoWidth / vid.videoHeight);
        }
        vid.currentTime = t;
        canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        ctx = canvas.getContext('2d');
        ctx.drawImage(vid, 0, 0, w, h);
        return canvas.toDataURL('image/jpeg');
      }
    };

    return Video;

  })(Ed.Model);

  Ed.Collections.Videos = (function(superClass) {
    extend(Videos, superClass);

    function Videos() {
      return Videos.__super__.constructor.apply(this, arguments);
    }

    Videos.prototype.model = Ed.Models.Video;

    Videos.prototype.url = "/api/videos";

    return Videos;

  })(Ed.Collection);

  Ed.Models.Quote = (function(superClass) {
    extend(Quote, superClass);

    function Quote() {
      return Quote.__super__.constructor.apply(this, arguments);
    }

    Quote.prototype.savedAttributes = [];

    Quote.prototype.defaults = {
      utterance: "",
      caption: ""
    };

    return Quote;

  })(Ed.Model);

  Ed.Models.Button = (function(superClass) {
    extend(Button, superClass);

    function Button() {
      return Button.__super__.constructor.apply(this, arguments);
    }

    Button.prototype.savedAttributes = [];

    Button.prototype.defaults = {
      label: "",
      url: "",
      color: ""
    };

    return Button;

  })(Ed.Model);

  Ed.Models.Notice = (function(superClass) {
    extend(Notice, superClass);

    function Notice() {
      this.discard = bind(this.discard, this);
      this.initialize = bind(this.initialize, this);
      return Notice.__super__.constructor.apply(this, arguments);
    }

    Notice.prototype.savedAttributes = [];

    Notice.prototype.defaults = {
      message: "Hi there.",
      notice_type: "info"
    };

    Notice.prototype.initialize = function() {
      return this.set("created_at", new Date);
    };

    Notice.prototype.discard = function() {
      var ref;
      return ((ref = this.collection) != null ? ref.remove(this) : void 0) || this.destroy();
    };

    return Notice;

  })(Backbone.Model);

  Ed.Collections.Notices = (function(superClass) {
    extend(Notices, superClass);

    function Notices() {
      return Notices.__super__.constructor.apply(this, arguments);
    }

    Notices.prototype.model = Ed.Models.Notice;

    Notices.prototype.comparator = "created_at";

    return Notices;

  })(Ed.Collection);

  Ed.Models.Job = (function(superClass) {
    extend(Job, superClass);

    function Job() {
      this.discard = bind(this.discard, this);
      this.setProgress = bind(this.setProgress, this);
      this.finish = bind(this.finish, this);
      return Job.__super__.constructor.apply(this, arguments);
    }

    Job.prototype.savedAttributes = [];

    Job.prototype.defaults = {
      status: "active",
      progress: 0,
      completed: false
    };

    Job.prototype.finish = function() {
      this.set("progress", 100);
      this.set('completed', true);
      return this.trigger('finished');
    };

    Job.prototype.setProgress = function(p) {
      var perc;
      if (p.lengthComputable) {
        perc = Math.round(10000 * p.loaded / p.total) / 100.0;
        return this.set("progress", perc);
      }
    };

    Job.prototype.discard = function() {
      var ref;
      return ((ref = this.collection) != null ? ref.remove(this) : void 0) || this.destroy();
    };

    return Job;

  })(Backbone.Model);

  Ed.Collections.Jobs = (function(superClass) {
    extend(Jobs, superClass);

    function Jobs() {
      return Jobs.__super__.constructor.apply(this, arguments);
    }

    Jobs.prototype.model = Ed.Models.Job;

    return Jobs;

  })(Backbone.Collection);

}).call(this);