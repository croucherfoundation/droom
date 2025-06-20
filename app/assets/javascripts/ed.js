//= require hamlcoffee
//= require 'underscore/underscore'
//= require 'backbone/backbone'
//= require 'backbone.marionette/lib/backbone.marionette'
//= require 'backbone.stickit/backbone.stickit'
//= require 'moment/moment'
//= require 'smartquotes/dist/smartquotes'
//= require 'medium-editor/dist/js/medium-editor'
//= require 'jquery-circle-progress/dist/circle-progress'

//= require_tree ./templates
//= require './ed/application'
//= require './ed/config'
//= require './ed/models'
//= require_tree './ed/views'
//= require_self

(function() {
  jQuery(function($) {
    document.execCommand('defaultParagraphSeparator', false, 'p');
    $.fn.edify = function(options) {
      if (options == null) {
        options = {};
      }
      return this.each(function() {
        var args;
        args = _.extend(options, {
          el: this
        });
        return new Ed.Application(args).start();
      });
    };
    return $('[data-editor="ed"]').edify();
  });

}).call(this);