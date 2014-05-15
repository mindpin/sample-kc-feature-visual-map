edge_equal = (e1, e2)->
  return e1[0] == e2[0] && e1[1] == e2[1]

class KnowledgeNet
  constructor: (json_obj)->
    @_points_map = {}
    @_edges = []

    # 是否已清理多余边
    @cleaned = false

    for p in json_obj['points']
      @_points_map[p.id] = {
        id: p.id
        name: p.name
        edges: []
        parents: []
        children: []
      }

    for e in json_obj['edges']
      parent_id = e['parent']
      child_id = e['child']

      @_edges.push [parent_id, child_id]

      parent = @find_by parent_id
      child = @find_by child_id

      parent.edges.push [parent_id, child_id]
      parent.children.push child_id

      child.edges.push [parent_id, child_id]
      child.parents.push parent_id


  find_by: (id)->
    @_points_map[id]


  points: ->
    if !@_points
      @_points = []
      for id of @_points_map
        @_points.push id
    @_points


  edges: ->
    @_edges


  roots: ->
    if !@_roots
      @_roots = []
      for id of @_points_map
        @_roots.push id if @is_root(id)
    @_roots


  is_root: (id)->
    p = @find_by(id)
    if p.parents.length == 0
      return true
    return false


  get_redundant_edges: ->
    _set = new DistanceSet(@)
    _arr = @roots().map (root_id)-> root_id

    # 宽度优先遍历
    while _arr.length > 0
      point = @find_by _arr.shift()
      _set.add point
      
      for child_id in point.children
        child = @find_by child_id
        if _set.is_parents_here child
          _arr.push child_id

      # console.log point.id, _arr

    @deeps = _set.deeps

    return _set.redundant_edges


  clean_redundant_edges: ->
    return if @cleaned

    for edge in @get_redundant_edges()
      @clean_edge edge
    @cleaned = true

  # edge like ['A', 'B']
  clean_edge: (edge)->
    parent_id = edge[0]
    child_id  = edge[1]
    parent    = @find_by parent_id
    child     = @find_by child_id

    # 从父节点移除子，以及移除相应的边
    parent.children = parent.children.filter (id)->
      id != child_id

    parent.edges = parent.edges.filter (e)->
      !edge_equal(e, edge)

    # 从子节点移除父，以及移除相应的边
    child.parents = child.parents.filter (id)->
      id != parent_id

    child.edges = child.edges.filter (e)->
      !edge_equal(e, edge)

    # 移除边
    @_edges = @_edges.filter (e)->
      !edge_equal(e, edge)

  get_deeps: ->
    @clean_redundant_edges()
    @deeps

  get_tree_data: ->
    @clean_redundant_edges()

    # deeps 排序
    arr = []
    for id of @deeps
      arr.push [@deeps[id], id]

    arr = arr.sort().map (item)->
      item[1]

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