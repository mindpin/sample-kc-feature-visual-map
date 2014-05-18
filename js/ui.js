// Generated by CoffeeScript 1.7.1
(function() {
  var KnowledgeNetGraph, Zoomer,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  jQuery(function() {
    if (jQuery('body.sample').length) {
      return jQuery.getJSON('data/js/js.json', function(data) {
        return new KnowledgeNetGraph(jQuery('.graph-paper'), data);
      });
    }
  });

  Zoomer = (function() {
    function Zoomer(host) {
      this.host = host;
      this.zoomin = __bind(this.zoomin, this);
      this.zoomout = __bind(this.zoomout, this);
      this.zoom_behavior = this.host.zoom_behavior;
    }

    Zoomer.prototype.zoomout = function() {
      var new_scale, scale;
      scale = this.zoom_behavior.scale();
      new_scale = scale > 1.414 ? 1.414 : scale > 1 ? 1 : scale > 0.707 ? 0.707 : scale > 0.5 ? 0.5 : scale > 0.354 ? 0.354 : 0.25;
      this.host.zoom_transition = true;
      return this.zoom_behavior.scale(new_scale).event(this.host.svg);
    };

    Zoomer.prototype.zoomin = function() {
      var new_scale, scale;
      scale = this.zoom_behavior.scale();
      new_scale = scale < 0.354 ? 0.354 : scale < 0.5 ? 0.5 : scale < 0.707 ? 0.707 : scale < 1 ? 1 : scale < 1.414 ? 1.414 : 2;
      this.host.zoom_transition = true;
      return this.zoom_behavior.scale(new_scale).event(this.host.svg);
    };

    return Zoomer;

  })();

  KnowledgeNetGraph = (function() {
    function KnowledgeNetGraph($elm, data) {
      var _ref;
      this.$elm = $elm;
      this.data = data;
      this.__zoom = __bind(this.__zoom, this);
      this.$paper = jQuery('<div></div>').addClass('knowledge-net-paper').appendTo(this.$elm);
      this.SCALE = [0.25, 2];
      this.CIRCLE_RADIUS = 15;
      _ref = [150, 180], this.NODE_WIDTH = _ref[0], this.NODE_HEIGHT = _ref[1];
      this.offset_x = 0;
      this.offset_y = 0;
      this.scale = 1;
      this.knet = new KnowledgeNet(this.data);
      this.draw();
    }

    KnowledgeNetGraph.prototype.draw = function() {
      this._svg();
      this._tree();
      this._links();
      this._nodes();
      this._events();
      this._bar();
      this._bar_events();
      return this._init_pos();
    };

    KnowledgeNetGraph.prototype._bar = function() {
      this.__bar_zoom();
      this.__bar_count();
      return this.__bar_point_info();
    };

    KnowledgeNetGraph.prototype.__bar_zoom = function() {
      this.$bar = jQuery('<div></div>').addClass('bar').appendTo(this.$paper);
      this.$scale = jQuery('<div></div>').addClass('scale').text('100 %').appendTo(this.$bar);
      this.$scale_minus = jQuery('<div></div>').addClass('scale-minus').html("<i class='fa fa-minus'></i>").appendTo(this.$bar);
      return this.$scale_plus = jQuery('<div></div>').addClass('scale-plus').html("<i class='fa fa-plus'></i>").appendTo(this.$bar);
    };

    KnowledgeNetGraph.prototype.__bar_count = function() {
      var arc, arcs, colors, common_count, h, inner_radius, outer_radius, start_count, svg, w;
      start_count = this.knet.roots().length;
      common_count = this.knet.points().length - start_count;
      this.$start_point_count = jQuery('<div></div>').addClass('start-points-count').html("<span>起始知识点</span>\n<span class='count'>" + start_count + "</span>").appendTo(this.$bar);
      this.$start_point_count = jQuery('<div></div>').addClass('common-points-count').html("<span>一般知识点</span>\n<span class='count'>" + common_count + "</span>").appendTo(this.$bar);
      this.$count_pie = jQuery('<div></div>').addClass('count-pie').appendTo(this.$bar);
      w = 150;
      h = 150;
      outer_radius = w / 2;
      inner_radius = w / 2.666;
      arc = d3.svg.arc().innerRadius(inner_radius).outerRadius(outer_radius);
      svg = d3.select(this.$count_pie[0]).append('svg').attr({
        'width': w,
        'height': h
      }).style({
        'margin': '25px 0 0 25px'
      });
      arcs = svg.selectAll('g.arc').data(d3.layout.pie()([start_count, common_count])).enter().append('g').attr({
        'class': 'arc',
        'transform': "translate(" + outer_radius + ", " + outer_radius + ")"
      });
      colors = ['#FFB43B', '#65B2EF'];
      return arcs.append('path').attr({
        'fill': function(d, i) {
          return colors[i];
        },
        'd': arc
      });
    };

    KnowledgeNetGraph.prototype.__bar_point_info = function() {
      return this.$point_info = jQuery('<div></div>').addClass('point-info').html("<h3>创建数组</h3>\n<p>允许的字符的集合</p>\n<div>\n  <span class='depend'>前置知识点：</span>\n  <span class='depend-count'></span>\n</div>").appendTo(this.$paper);
    };

    KnowledgeNetGraph.prototype.show_point_info = function(point, elm, direct_depend_count, indirect_depend_count) {
      var $e, dc, desc, l, name, o, o1, t;
      name = point.name;
      desc = point.desc;
      this.$point_info.find('h3').html(name);
      this.$point_info.find('p').html(desc);
      dc = direct_depend_count + indirect_depend_count;
      if (dc === 0) {
        this.$point_info.find('span.depend').hide();
        this.$point_info.find('span.depend-count').html('这是起始知识点');
      } else {
        this.$point_info.find('span.depend').show();
        this.$point_info.find('span.depend-count').html(dc);
      }
      $e = jQuery(elm);
      o = $e.offset();
      o1 = this.$paper.offset();
      l = o.left - o1.left + this.CIRCLE_RADIUS * 2 * this.scale + 30;
      t = o.top - o1.top + this.CIRCLE_RADIUS * this.scale - 30;
      return this.$point_info.addClass('show').css({
        'left': l,
        'top': t
      });
    };

    KnowledgeNetGraph.prototype.hide_point_info = function() {
      return this.$point_info.removeClass('show');
    };

    KnowledgeNetGraph.prototype._bar_events = function() {
      this.$scale_minus.on('click', this.zoomer.zoomout);
      return this.$scale_plus.on('click', this.zoomer.zoomin);
    };

    KnowledgeNetGraph.prototype._svg = function() {
      this.zoom_behavior = d3.behavior.zoom().scaleExtent(this.SCALE).center([this.$elm.width() / 2, this.$elm.height() / 2]).on('zoom', this.__zoom);
      this.svg = d3.select(this.$paper[0]).append('svg').attr('class', 'knsvg').call(this.zoom_behavior).on('dblclick.zoom', null);
      this.graph = this.svg.append('g');
      return this.zoomer = new Zoomer(this);
    };

    KnowledgeNetGraph.prototype.__zoom = function() {
      var g, scale, translate;
      scale = this.zoom_behavior.scale();
      translate = this.zoom_behavior.translate();
      this.__set_text_class(scale);
      g = this.zoom_transition ? this.graph.transition() : this.graph;
      this.zoom_transition = false;
      g.attr('transform', "translate(" + (translate[0] + this.offset_x * scale) + ", " + translate[1] + ") scale(" + scale + ")");
      this.$scale.text("" + (Math.round(scale * 100)) + " %");
      this.scale = scale;
      return this.hide_point_info();
    };

    KnowledgeNetGraph.prototype.__set_text_class = function(scale) {
      var klass;
      klass = ['name'];
      if (scale < 0.75) {
        klass.push('hide');
      }
      return this.name_texts.attr({
        'class': klass.join(' ')
      });
    };

    KnowledgeNetGraph.prototype._tree = function() {
      var imarginay_root, tree;
      this.tree_data = this.knet.get_tree_nesting_data();
      imarginay_root = {
        children: this.tree_data.roots
      };
      tree = d3.layout.tree().nodeSize([this.NODE_WIDTH, this.NODE_HEIGHT]);
      this.dataset_nodes = tree.nodes(imarginay_root).slice(1);
      return this.dataset_edges = this.tree_data.edges;
    };

    KnowledgeNetGraph.prototype._links = function() {
      return this.links = this.graph.selectAll('.link').data(this.dataset_edges).enter().append('path').attr({
        'd': d3.svg.diagonal(),
        'class': 'link'
      });
    };

    KnowledgeNetGraph.prototype._nodes = function() {
      this.nodes = this.graph.selectAll('.node').data(this.dataset_nodes).enter().append('g').attr({
        'class': 'node',
        'transform': function(d) {
          return "translate(" + d.x + ", " + d.y + ")";
        }
      });
      this.circles = this.nodes.append('circle').attr({
        'r': this.CIRCLE_RADIUS,
        'class': (function(_this) {
          return function(d) {
            var klass;
            klass = [];
            if (d.depth === 1) {
              klass.push('start-point');
            }
            return klass.join(' ');
          };
        })(this)
      });
      this.name_texts = this.nodes.append('text').attr({
        'y': 45,
        'text-anchor': 'middle'
      }).each(function(d, i) {
        var dy, j, str, _i, _len, _ref, _results;
        _ref = KnowledgeNet.break_text(d.name);
        _results = [];
        for (j = _i = 0, _len = _ref.length; _i < _len; j = ++_i) {
          str = _ref[j];
          dy = j === 0 ? '0' : '1.5em';
          _results.push(d3.select(this).append('tspan').attr({
            'x': 0,
            'dy': dy
          }).text(str));
        }
        return _results;
      });
      return this.__set_text_class(1);
    };

    KnowledgeNetGraph.prototype._init_pos = function() {
      var first_node;
      first_node = this.tree_data.roots[0];
      this.offset_x = -first_node.x + this.$elm.width() * 0.4;
      return this.zoom_behavior.scale(0.75).event(this.svg);
    };

    KnowledgeNetGraph.prototype._events = function() {
      var that;
      that = this;
      return this.circles.on('mouseover', function(d, i) {
        var d0, depend_point_ids, direct_depend_count, dr, id, links, parent, stack, _i, _len, _ref, _ref1;
        links = that.links.filter(function(link) {
          return link.target.id === d.id;
        });
        links.attr({
          'class': 'link direct-depend'
        });
        d0 = that.knet.find_by(d.id);
        stack = d0.parents.map(function(id) {
          return that.knet.find_by(id);
        });
        depend_point_ids = [];
        while (stack.length > 0) {
          dr = stack.shift();
          _ref = dr.parents;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            id = _ref[_i];
            parent = that.knet.find_by(id);
            stack.push(parent);
            if (_ref1 = parent.id, __indexOf.call(depend_point_ids, _ref1) < 0) {
              depend_point_ids.push(parent.id);
            }
          }
          that.links.filter(function(link) {
            return link.target.id === dr.id;
          }).attr({
            'class': 'link depend'
          });
        }
        that.circles.filter(function(c) {
          var _ref2, _ref3;
          return (_ref2 = c.id, __indexOf.call(depend_point_ids, _ref2) >= 0) || (_ref3 = c.id, __indexOf.call(d0.parents, _ref3) >= 0);
        }).attr({
          'class': function(d) {
            if (d.depth === 1) {
              return 'start-point';
            }
            return 'depend';
          }
        });
        direct_depend_count = links[0].length;
        return that.show_point_info(d, this, direct_depend_count, depend_point_ids.length);
      }).on('mouseout', function(d) {
        that.links.attr({
          'class': 'link'
        });
        that.circles.attr({
          'class': function(d) {
            if (d.depth === 1) {
              return 'start-point';
            }
          }
        });
        return that.hide_point_info();
      }).on('click', function(d) {});
    };

    return KnowledgeNetGraph;

  })();

}).call(this);

//# sourceMappingURL=ui.map
