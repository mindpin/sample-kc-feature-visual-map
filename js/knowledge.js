// Generated by CoffeeScript 1.7.1
(function() {
  var DistanceSet, KnowledgeNet, edge_equal,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  edge_equal = function(e1, e2) {
    return e1[0] === e2[0] && e1[1] === e2[1];
  };

  KnowledgeNet = (function() {
    function KnowledgeNet(json_obj) {
      var child, child_id, e, p, parent, parent_id, _i, _j, _len, _len1, _ref, _ref1;
      this._points_map = {};
      this._edges = [];
      this.cleaned = false;
      _ref = json_obj['points'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        this._points_map[p.id] = {
          id: p.id,
          name: p.name,
          desc: p.desc,
          edges: [],
          parents: [],
          children: []
        };
      }
      _ref1 = json_obj['edges'];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        e = _ref1[_j];
        parent_id = e['parent'];
        child_id = e['child'];
        this._edges.push([parent_id, child_id]);
        parent = this.find_by(parent_id);
        child = this.find_by(child_id);
        parent['edges'].push([parent_id, child_id]);
        parent['children'].push(child_id);
        child['edges'].push([parent_id, child_id]);
        child['parents'].push(parent_id);
      }
    }

    KnowledgeNet.prototype.find_by = function(id) {
      return this._points_map[id];
    };

    KnowledgeNet.prototype.points = function() {
      var id;
      return this._points != null ? this._points : this._points = (function() {
        var _results;
        _results = [];
        for (id in this._points_map) {
          _results.push(id);
        }
        return _results;
      }).call(this);
    };

    KnowledgeNet.prototype.edges = function() {
      return this._edges;
    };

    KnowledgeNet.prototype.roots = function() {
      var id;
      return this._roots != null ? this._roots : this._roots = (function() {
        var _results;
        _results = [];
        for (id in this._points_map) {
          if (this.is_root(id)) {
            _results.push(id);
          }
        }
        return _results;
      }).call(this);
    };

    KnowledgeNet.prototype.is_root = function(id) {
      return this.find_by(id).parents.length === 0;
    };

    KnowledgeNet.prototype.get_redundant_edges = function() {
      var child, child_id, id, point, _arr, _i, _len, _ref, _set;
      _set = new DistanceSet(this);
      _arr = (function() {
        var _i, _len, _ref, _results;
        _ref = this.roots();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          id = _ref[_i];
          _results.push(id);
        }
        return _results;
      }).call(this);
      while (_arr.length > 0) {
        point = this.find_by(_arr.shift());
        _set.add(point);
        _ref = point.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child_id = _ref[_i];
          child = this.find_by(child_id);
          if (_set.is_parents_here(child)) {
            _arr.push(child_id);
          }
        }
      }
      this.deeps = _set.deeps;
      return _set.redundant_edges;
    };

    KnowledgeNet.prototype.clean_redundant_edges = function() {
      var edge, _i, _len, _ref;
      if (!this.cleaned) {
        _ref = this.get_redundant_edges();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          edge = _ref[_i];
          this.clean_edge(edge);
        }
        return this.cleaned = true;
      }
    };

    KnowledgeNet.prototype.clean_edge = function(edge) {
      var child, child_id, parent, parent_id;
      parent_id = edge[0], child_id = edge[1];
      parent = this.find_by(parent_id);
      child = this.find_by(child_id);
      parent.children = parent.children.filter(function(id) {
        return id !== child_id;
      });
      parent.edges = parent.edges.filter(function(e) {
        return !edge_equal(e, edge);
      });
      child.parents = child.parents.filter(function(id) {
        return id !== parent_id;
      });
      child.edges = child.edges.filter(function(e) {
        return !edge_equal(e, edge);
      });
      return this._edges = this._edges.filter(function(e) {
        return !edge_equal(e, edge);
      });
    };

    KnowledgeNet.prototype.get_deeps = function() {
      this.clean_redundant_edges();
      return this.deeps;
    };

    KnowledgeNet.prototype.get_tree_data = function() {
      var arr, edges, id, pid, point, stack, _i, _j, _len, _len1;
      this.clean_redundant_edges();
      arr = this.__deeps_arr();
      stack = [];
      edges = [];
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        id = arr[_i];
        point = this.find_by(id);
        for (_j = 0, _len1 = stack.length; _j < _len1; _j++) {
          pid = stack[_j];
          if (__indexOf.call(point.parents, pid) >= 0) {
            edges.push([pid, id]);
            break;
          }
        }
        stack.unshift(id);
      }
      return {
        'points': arr,
        'edges': edges
      };
    };

    KnowledgeNet.prototype.get_tree_nesting_data = function() {
      var arr, e, edges, id, map, pid, point, re, source, stack, target, _i, _j, _k, _len, _len1, _len2;
      this.clean_redundant_edges();
      arr = this.__deeps_arr();
      map = {};
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        id = arr[_i];
        point = this.find_by(id);
        map[id] = {
          id: point.id,
          name: point.name,
          desc: point.desc,
          children: [],
          deep: this.deeps[id]
        };
      }
      stack = [];
      for (_j = 0, _len1 = arr.length; _j < _len1; _j++) {
        id = arr[_j];
        point = this.find_by(id);
        for (_k = 0, _len2 = stack.length; _k < _len2; _k++) {
          pid = stack[_k];
          if (__indexOf.call(point.parents, pid) >= 0) {
            map[pid].children.push(map[id]);
            break;
          }
        }
        stack.unshift(id);
      }
      re = (function() {
        var _l, _len3, _ref, _results;
        _ref = this.roots();
        _results = [];
        for (_l = 0, _len3 = _ref.length; _l < _len3; _l++) {
          id = _ref[_l];
          this.__count(map, id);
          _results.push(map[id]);
        }
        return _results;
      }).call(this);
      edges = (function() {
        var _l, _len3, _ref, _results;
        _ref = this.edges();
        _results = [];
        for (_l = 0, _len3 = _ref.length; _l < _len3; _l++) {
          e = _ref[_l];
          source = map[e[0]];
          target = map[e[1]];
          _results.push({
            "source": source,
            "target": target
          });
        }
        return _results;
      }).call(this);
      return {
        "roots": re.sort(function(a, b) {
          return b.count - a.count;
        }),
        "edges": edges
      };
    };

    KnowledgeNet.prototype.__count = function(map, pid) {
      var child_id, map_point, o_point, _i, _len, _ref;
      map_point = map[pid];
      o_point = this.find_by(pid);
      if (!map_point.count) {
        map_point.count = 1;
        _ref = o_point.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child_id = _ref[_i];
          map_point.count += this.__count(map, child_id);
        }
      }
      return map_point.count;
    };

    KnowledgeNet.prototype.__deeps_arr = function() {
      var id;
      return ((function() {
        var _results;
        _results = [];
        for (id in this.deeps) {
          _results.push([this.deeps[id], id]);
        }
        return _results;
      }).call(this)).sort(function(a, b) {
        return a[0] - b[0];
      }).map(function(item) {
        return item[1];
      });
    };

    KnowledgeNet.break_text = function(text) {
      var arr, length, re, slen, tmp, x, _i, _len;
      arr = this.__split(text);
      length = 0;
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        x = arr[_i];
        length += x[1];
      }
      slen = this.__slen(length);
      re = [];
      tmp = ['', 0];
      while (arr.length > 0) {
        if (tmp[1] >= slen) {
          re.push(tmp[0]);
          tmp = ['', 0];
        }
        x = arr.shift();
        tmp[0] += x[0];
        tmp[1] += x[1];
      }
      re.push(tmp[0]);
      return re;
    };

    KnowledgeNet.__split = function(text) {
      var arr, push_stack, re, s, stack, _i, _len;
      arr = text.split('');
      re = [];
      stack = '';
      push_stack = function() {
        if (stack.length > 0) {
          re.push([stack, Math.ceil(stack.length / 2)]);
          return stack = '';
        }
      };
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        s = arr[_i];
        if (s.match(/[\u4e00-\u9fa5]/)) {
          push_stack();
          re.push([s, 1]);
        } else {
          stack = stack + s;
        }
      }
      push_stack();
      return re;
    };

    KnowledgeNet.__slen = function(length) {
      var c;
      c = Math.floor((length - 1) / 6);
      return Math.ceil(length / (c + 1));
    };

    return KnowledgeNet;

  })();

  DistanceSet = (function() {
    function DistanceSet(net) {
      this.net = net;
      this.set = {};
      this.redundant_edges = [];
      this.deeps = {};
    }

    DistanceSet.prototype.is_parents_here = function(point) {
      var parent_id, _i, _len, _ref;
      _ref = point.parents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        parent_id = _ref[_i];
        if (!(parent_id in this.set)) {
          return false;
        }
      }
      return true;
    };

    DistanceSet.prototype.add = function(point) {
      var deep;
      this.set[point.id] = {};
      deep = this._r(point, point, 1);
      return this.deeps[point.id] = deep;
    };

    DistanceSet.prototype._r = function(current_point, point, distance) {
      var d, deep, parent_id, _i, _len, _ref;
      deep = 1;
      _ref = current_point.parents;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        parent_id = _ref[_i];
        this._merge(parent_id, point.id, distance);
        d = this._r(this.net.find_by(parent_id), point, distance + 1);
        deep = Math.max(deep, this.deeps[parent_id] + 1);
      }
      return deep;
    };

    DistanceSet.prototype._merge = function(target_id, point_id, distance) {
      var d0;
      d0 = this.set[target_id][point_id];
      if (!d0) {
        this.set[target_id][point_id] = distance;
        return;
      }
      this.set[target_id][point_id] = Math.max(d0, distance);
      if (d0 !== distance && Math.min(d0, distance) === 1) {
        return this.redundant_edges.push([target_id, point_id]);
      }
    };

    return DistanceSet;

  })();

  KnowledgeNet.DistanceSet = DistanceSet;

  window.KnowledgeNet = KnowledgeNet;

}).call(this);

//# sourceMappingURL=knowledge.map
