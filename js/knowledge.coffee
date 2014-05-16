edge_equal = (e1, e2)->
  e1[0] == e2[0] and e1[1] == e2[1]

class KnowledgeNet
  constructor: (json_obj)->
    @_points_map = {}
    @_edges = []

    # 是否已清理多余边
    @cleaned = false

    for p in json_obj['points']
      @_points_map[p.id] =
        id: p.id
        name: p.name
        edges: []
        parents: []
        children: []

    for e in json_obj['edges']
      parent_id = e['parent']
      child_id = e['child']

      @_edges.push [parent_id, child_id]

      parent = @find_by parent_id
      child = @find_by child_id

      parent['edges'].push [parent_id, child_id]
      parent['children'].push child_id

      child['edges'].push [parent_id, child_id]
      child['parents'].push parent_id


  find_by: (id)->
    @_points_map[id]


  points: ->
    @_points ?= (id for id of @_points_map)


  edges: ->
    @_edges


  roots: ->
    @_roots ?= (id for id of @_points_map when @is_root id)


  is_root: (id)->
    @find_by(id).parents.length is 0


  get_redundant_edges: ->
    _set = new DistanceSet(@)
    _arr = (id for id in @roots())

    # 宽度优先遍历
    while _arr.length > 0
      point = @find_by _arr.shift()
      _set.add point
      
      for child_id in point.children
        child = @find_by child_id
        _arr.push child_id if _set.is_parents_here child
          
    @deeps = _set.deeps

    return _set.redundant_edges


  clean_redundant_edges: ->
    unless @cleaned
      @clean_edge edge for edge in @get_redundant_edges()
      @cleaned = true

  # edge like ['A', 'B']
  clean_edge: (edge)->
    [parent_id, child_id] = edge
    parent = @find_by parent_id
    child  = @find_by child_id

    # 从父节点移除子，以及移除相应的边
    parent.children = parent.children.filter (id)->
      id isnt child_id

    parent.edges = parent.edges.filter (e)->
      not edge_equal(e, edge)

    # 从子节点移除父，以及移除相应的边
    child.parents = child.parents.filter (id)->
      id isnt parent_id

    child.edges = child.edges.filter (e)->
      not edge_equal(e, edge)

    # 移除边
    @_edges = @_edges.filter (e)->
      not edge_equal(e, edge)

  get_deeps: ->
    @clean_redundant_edges()
    @deeps

  get_tree_data: ->
    @clean_redundant_edges()

    arr = @__deeps_arr()

    # 添加边
    stack = []
    edges = []
    for id in arr
      point = @find_by id
      for pid in stack
        if pid in point.parents
          edges.push [pid, id]
          break
      stack.unshift id

    return {
      'points': arr
      'edges': edges
    }


  get_tree_nesting_data: ->
    @clean_redundant_edges()

    arr = @__deeps_arr()

    map = {}
    for id in arr
      point = @find_by id
      map[id] =
        id: point.id
        name: point.name
        children: []

    stack = []
    for id in arr
      point = @find_by id
      for pid in stack
        if pid in point.parents
          map[pid].children.push map[id]
          break
      stack.unshift id

    re = (map[id] for id in @roots())

    @__count(p) for p in re

    return re.sort (a, b)-> b.count - a.count

  __count: (point)->
    point.count = 1
    for child in point.children
      point.count += @__count(child)
    point.count

  __deeps_arr: ->
    # deeps 排序数组
    ([@deeps[id], id] for id of @deeps)
      .sort()
      .map (item)-> item[1]

# SET = {}
# RE = {}
# 宽度优先遍历节点
# 如果节点的父节点都在 SET 中
#   将节点置入 SET
#   处理 SET 中各个节点的路径长度信息
#   一旦发现冲突，解决冲突，并将导致冲突的边置入 RE

# 记录节点之间的路径长度
class DistanceSet
  constructor: (@net)->
    @set = {}
    @redundant_edges = []
    @deeps = {}

  is_parents_here: (point)->
    for parent_id in point.parents
      return false if !(parent_id of @set)
    return true

  add: (point)->
    @set[point.id] = {}
    deep = @_r(point, point, 1)
    @deeps[point.id] = deep

  _r: (current_point, point, distance)->
    deep = 1
    for parent_id in current_point.parents
      @_merge parent_id, point.id, distance
      d = @_r @net.find_by(parent_id), point, distance + 1
      deep = Math.max(deep, @deeps[parent_id] + 1)
    return deep

  _merge: (target_id, point_id, distance)->
    d0 = @set[target_id][point_id]

    if !d0
      @set[target_id][point_id] = distance
      return

    @set[target_id][point_id] = Math.max d0, distance

    if d0 != distance && Math.min(d0, distance) == 1
      @redundant_edges.push [target_id, point_id]


KnowledgeNet.DistanceSet = DistanceSet
window.KnowledgeNet = KnowledgeNet


jQuery ->
  if jQuery('body').hasClass('sample')
    jQuery.ajax
      url: 'data/js/js.json'
      # url: 'fixture/graph.json'
      type: 'GET'
      dataType: 'json'
      success: (obj)->
        graph = new Graph
        graph.draw(obj)

class Graph
  constructor: ->
    # nothing

  draw: (obj)->
    @knet = new KnowledgeNet obj

    @_draw_svg()
    @_draw_tree()

  _draw_svg: ->
    @screen_w = 16000
    @screen_h = 8000

    @svg = d3.select('.graph-paper').append('svg')
        .attr('width', @screen_w)
        .attr('height', @screen_h)

    zoom_behavior = d3.behavior.zoom()
      .scaleExtent([0.25, 2])
      .on("zoom", @_zoom)

    @g1 = @svg.append('g')
        .call zoom_behavior
    
    @g2 = @svg.append('g')
      # .attr 'transform', "translate(2300, 0)"

    @g1.append "rect"
      .attr "class", "overlay"
      .attr 'width', @screen_w
      .attr 'height', @screen_h
      .style 'fill', 'none'
      .style 'pointer-events', 'all'


  _zoom: =>
    scale = d3.event.scale
    if scale < 0.8
      @text.style 'display', 'none'
    else
      @text.style 'display', ''

    translate = d3.event.translate

    # off = 0



    @g2.attr 'transform', "translate(#{translate[0] + off}, #{translate[1]})scale(#{scale})"


  _draw_tree: ->
    tree_data = @knet.get_tree_nesting_data()

    console.log tree_data

    obj = {
      name:'ROOT'
      children: tree_data
    }

    # ------------
    # D3

    tree = d3.layout.tree()
      # .size [@screen_w * 3, @screen_h * 3]
      .nodeSize [80, 100]
      .separation (a, b)->
        if a.parent == b.parent then 1 else 2;

    diagonal = d3.svg.diagonal()
      .projection (d)->
        [d.x, d.y]

    nodes = tree.nodes obj
    links = tree.links nodes

    node_enter = @g2.selectAll('.node')
      .data nodes
      .enter()
      .append 'g'
      .attr 'class', 'node'
      .attr 'transform', (d)->
        "translate(#{d.x}, #{d.y})"

    node_enter.append 'circle'
      .attr 'r', 15
      .style 'fill', '#232B2D'
      .style 'stroke', '#65B2EF'
      .style 'stroke-width', 5
      .style 'display', (d)->
        if d.name == 'ROOT' then 'none'

    @text = node_enter.append 'text'
      .attr 'dy', 45
      .attr 'text-anchor', 'middle'
      .text (d)-> d.name
      .style 'font-family', 'arial, 微软雅黑'
      .style 'font-size', '14px'
      # .style 'font-weight', 'bold'
      .style 'fill', '#fff'
      .style 'display', (d)->
        if d.name == 'ROOT' then 'none'

    @g2.selectAll('.link')
      .data links
      .enter()
      .insert 'path', 'g'
      .attr 'class', 'link'
      .attr 'd', diagonal
      .style 'fill', 'none'
      .style 'stroke', '#6F7B7E'
      .style 'stroke-width', '3px'
      .style 'display', (d)->
        if d.source.name == 'ROOT' then 'none'