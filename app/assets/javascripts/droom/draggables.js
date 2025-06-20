(function() {
  var DragManager, UserMerger,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  jQuery(function($) {
    var SortableFiling;
    $.fn.sortable_list = function() {
      return this.each(function() {
        return new Sortable(this, {
          sort: true
        });
      });
    };
    $.fn.sortable_files = function() {
      return this.each(function() {
        return new SortableFiling(this);
      });
    };
    return SortableFiling = (function() {
      function SortableFiling(element) {
        this.setParent = bind(this.setParent, this);
        this.setPosition = bind(this.setPosition, this);
        this.beginDrag = bind(this.beginDrag, this);
        this._container = $(element);
        this._folder_id = this._container.data('folderId');
        this._droppables = this._container.parents('[data-droppable]');
        this._sortable = new Sortable(element, {
          group: "files",
          sort: true,
          pull: true,
          put: true,
          revertClone: true,
          onStart: this.beginDrag,
          onUpdate: this.setPosition,
          onAdd: this.setPosition
        });
      }

      SortableFiling.prototype.beginDrag = function(e) {
        console.log("beginDrag", this._droppables);
        return $('[data-droppable]').trigger("sorting");
      };

      SortableFiling.prototype.setPosition = function(e) {
        var $el, doc_id, params, update, url;
        $('[data-droppable]').trigger("not_sorting");
        $el = $(e.item || e.dragged);
        if (doc_id = $el.data('docId')) {
          url = "/documents/" + doc_id + "/reposition";
          params = {
            document: {
              position: e.newIndex + 1,
              folder_id: this._folder_id
            }
          };
          return update = $.ajax({
            method: "PUT",
            url: url,
            data: params,
            success: function() {
              return $el.signal_confirmation();
            }
          });
        }
      };

      SortableFiling.prototype.setParent = function(e) {
        return console.log("setParent", e.item, e.from);
      };

      return SortableFiling;

    })();
  });

  $.fn.drag_manager = function() {
    return this.each(function() {
      return new DragManager(this);
    });
  };

  DragManager = (function() {
    function DragManager(element) {
      this.stopListening = bind(this.stopListening, this);
      this.startListening = bind(this.startListening, this);
      this.reset = bind(this.reset, this);
      this.undroppable = bind(this.undroppable, this);
      this.droppable = bind(this.droppable, this);
      this.showNodrop = bind(this.showNodrop, this);
      this.showDrop = bind(this.showDrop, this);
      this.dropSuccess = bind(this.dropSuccess, this);
      this.dropFail = bind(this.dropFail, this);
      this.enactDrop = bind(this.enactDrop, this);
      this.confirmDrop = bind(this.confirmDrop, this);
      this.possibleDrop = bind(this.possibleDrop, this);
      this.dragMove = bind(this.dragMove, this);
      this.possibleDrag = bind(this.possibleDrag, this);
      var manager;
      this._container = $(element);
      this.draggables = this._container.find('.draggable');
      manager = this;
      this.draggables.on('mousedown', function(e) {
        return manager.possibleDrag(e, this);
      });
    }

    DragManager.prototype.possibleDrag = function(e, el) {
      e.preventDefault();
      this.el = $(el);
      this.clone = void 0;
      this.origin = this.el.position();
      this.click = {
        x: e.pageX,
        y: e.pageY
      };
      return this.startListening();
    };

    DragManager.prototype.dragMove = function(e) {
      var dx, dy, pos, ref;
      e.preventDefault();
      dx = e.pageX - this.click.x;
      dy = e.pageY - this.click.y;
      if (Math.sqrt(Math.pow(dy, 2) + Math.pow(dx, 2)) > 5) {
        if (this.clone == null) {
          this.clone = this.el.clone().addClass('cloned dragging').appendTo(this._container);
          this.clone.attr('id', this.el.attr('id') + "_dragging");
        }
        pos = {
          left: this.origin.left + dx,
          top: this.origin.top + dy,
          width: this.el.width(),
          height: this.el.height()
        };
        this.clone.css(pos);
        this.el.addClass('dragged');
        return this.clone.show();
      } else {
        if ((ref = this.clone) != null) {
          ref.hide();
        }
        return this.el.removeClass('dragged');
      }
    };

    DragManager.prototype.possibleDrop = function(e) {
      var merging;
      this.stopListening();
      merging = false;
      if (this.del && this.confirmDrop(this.del)) {
        this.enactDrop(this.del, this.el).done(this.dropSuccess).fail(this.dropFail);
        merging = true;
      }
      if (!(merging || !this.clone)) {
        return this.showNodrop();
      }
    };

    DragManager.prototype.confirmDrop = function(del) {
      if (del == null) {
        del = this.del;
      }
      return false;
    };

    DragManager.prototype.enactDrop = function(droppee, dropped) {};

    DragManager.prototype.dropFail = function(xhr, status, error) {};

    DragManager.prototype.dropSuccess = function(response) {
      return this.showDrop();
    };

    DragManager.prototype.showDrop = function() {
      var destination, flyto;
      if (this.del) {
        destination = this.del.offset();
        flyto = {
          left: destination.left + this.del.width() / 2,
          top: destination.top + this.del.height() / 2,
          width: 0,
          height: 0,
          opacity: 0
        };
        return this.clone.animate(flyto, 250, 'glide', (function(_this) {
          return function() {
            var del;
            _this.del.removeClass("splash droppable").addClass("splash");
            del = _this.del;
            window.setTimeout(function() {
              _this.el.remove();
              _this.del.addClass("pending");
              return _this.reset();
            }, 250);
            return window.setTimeout(function() {
              return del != null ? del.refresh() : void 0;
            }, 10000);
          };
        })(this));
      }
    };

    DragManager.prototype.showNodrop = function() {
      var flyback;
      if (this.clone && this.origin) {
        flyback = _.extend(this.origin, {
          opacity: 0
        });
        this.clone.removeClass('dragging');
        return this.clone.animate(flyback, 400, 'boing', this.reset);
      }
    };

    DragManager.prototype.droppable = function(e) {
      this.del = $(e.originalEvent.currentTarget);
      return this.del.addClass('droppable');
    };

    DragManager.prototype.undroppable = function(e) {
      var ref;
      if ((ref = this.del) != null) {
        ref.removeClass('droppable');
      }
      return this.del = null;
    };

    DragManager.prototype.reset = function() {
      var ref;
      if ((ref = this.clone) != null) {
        ref.remove();
      }
      this.draggables.removeClass('dragged droppable');
      this.el = null;
      this.del = null;
      this.clone = null;
      this.origin = null;
      return this.click = null;
    };

    DragManager.prototype.startListening = function() {
      $(document).on("mousemove", this.dragMove).on("mouseup", this.possibleDrop);
      return this.draggables.on("mouseenter", this.droppable).on("mouseleave", this.undroppable);
    };

    DragManager.prototype.stopListening = function() {
      $(document).off("mousemove", this.dragMove).off("mouseup", this.possibleDrop);
      return this.draggables.off("mouseenter", this.droppable).off("mouseleave", this.undroppable);
    };

    return DragManager;

  })();

  $.fn.user_merger = function() {
    return this.each(function() {
      return new UserMerger(this);
    });
  };

  UserMerger = (function(superClass) {
    extend(UserMerger, superClass);

    function UserMerger() {
      this.dropFail = bind(this.dropFail, this);
      this.enactDrop = bind(this.enactDrop, this);
      this.confirmDrop = bind(this.confirmDrop, this);
      return UserMerger.__super__.constructor.apply(this, arguments);
    }

    UserMerger.prototype.confirmDrop = function(del) {
      var inner_item, inner_name, outer_item, outer_name;
      if (del == null) {
        del = this.del;
      }
      console.log("confirmDrop:", this.el, this.del);
      outer_item = this.del.data('user');
      outer_name = this.del.find('span.name').text();
      inner_item = this.el.data('user');
      inner_name = this.el.find('span.name').text();
      return outer_item !== inner_item && confirm("Really merge " + inner_name + " (#" + inner_item + ") into " + outer_name + " (#" + outer_item + ")?");
    };

    UserMerger.prototype.enactDrop = function(droppee, dropped) {
      var inner_id, outer_id, url;
      outer_id = droppee.data('user');
      inner_id = dropped.data('user');
      url = "/users/" + outer_id + "/subsume/" + inner_id + ".json";
      return $.ajax({
        url: url,
        method: "PUT"
      });
    };

    UserMerger.prototype.dropFail = function(xhr, status, error) {
      var ref;
      if ((ref = this.del) != null) {
        ref.signal_error();
      }
      return this.showNodrop();
    };

    return UserMerger;

  })(DragManager);

}).call(this);