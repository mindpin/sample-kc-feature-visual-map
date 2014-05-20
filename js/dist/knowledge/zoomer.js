// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(function(require, exports, module) {
    var Zoomer;
    require('d3');
    return Zoomer = (function() {
      function Zoomer(host) {
        this.host = host;
        this.zoomed = __bind(this.zoomed, this);
        this.zoomin = __bind(this.zoomin, this);
        this.zoomout = __bind(this.zoomout, this);
        this.SCALE_EXTENT = [0.25, 2];
        this.scale = 1;
        this.zoom_transition = false;
        this.viewport_w = this.host.$elm.width();
        this.viewport_h = this.host.$elm.height();
        this.center_x = this.viewport_w / 2;
        this.center_y = this.viewport_h / 2;
        this.zoom_behavior = d3.behavior.zoom().scaleExtent(this.SCALE_EXTENT).center([this.center_x, this.center_y]).on('zoom', this.zoomed);
      }

      Zoomer.prototype.zoomout = function() {
        var new_scale, scale;
        scale = this.zoom_behavior.scale();
        new_scale = scale > 1.414 ? 1.414 : scale > 1 ? 1 : scale > 0.707 ? 0.707 : scale > 0.5 ? 0.5 : scale > 0.354 ? 0.354 : 0.25;
        this.zoom_transition = true;
        return this.scaleto(new_scale);
      };

      Zoomer.prototype.zoomin = function() {
        var new_scale, scale;
        scale = this.zoom_behavior.scale();
        new_scale = scale < 0.354 ? 0.354 : scale < 0.5 ? 0.5 : scale < 0.707 ? 0.707 : scale < 1 ? 1 : scale < 1.414 ? 1.414 : 2;
        this.zoom_transition = true;
        return this.scaleto(new_scale);
      };

      Zoomer.prototype.zoomed = function() {
        this.scale = this.zoom_behavior.scale();
        this.translate = this.zoom_behavior.translate();
        this.host.deal_zoom(this.scale, this.translate, this.zoom_transition);
        return this.zoom_transition = false;
      };

      Zoomer.prototype.scaleto = function(new_scale) {
        var new_translate, scale, translate;
        scale = this.zoom_behavior.scale();
        translate = this.zoom_behavior.translate();
        new_translate = [translate[0] + this.center_x * scale - this.center_x * new_scale, translate[1] + this.center_y * scale - this.center_y * new_scale];
        return this.zoom_behavior.scale(new_scale).translate(new_translate).event(this.host.svg);
      };

      return Zoomer;

    })();
  });

}).call(this);

//# sourceMappingURL=zoomer.map
