class KNPoint
  constructor: (@id, @name)->
    @edges = []
    @parents = []
    @children = []

class KnowledgeNet
  constructor: (json_obj)->
    @_points_map = {}
    @_edges = []

    for p in json_obj['points']
      @_points_map[p.id] = new KNPoint(p.id, p.name)

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


  points: ->
    if !@_points
      @_points = []
      for id of @_points_map
        @_points.push @find_by(id)
    @_points


  edges: ->
    @_edges


  find_by: (id)->
    @_points_map[id]


  roots: ->
    if !@_roots
      @_roots = []
      for id of @_points_map
        p = @find_by(id)
        if p.parents.length == 0
          @_roots.push p
    @_roots


  is_root: (id)->
    p = @find_by(id)
    if p.parents.length == 0
      return true
    return false


  get_redundant_edges: ->
    _set = new DistanceSet(@)
    _arr = @roots().map (p)->
      p.id

    # 宽度优先遍历
    while _arr.length > 0
      point = @find_by _arr.shift()

      _set.add point
      
      for child_id in point.children
        child = @find_by child_id
        if _set.is_parents_here child
          _arr.push child_id

      # console.log point.id, _arr

    return _set.redundant_edges


  clean_redundant_edges: ->
    for edge in @get_redundant_edges()
      @clean_edge edge

  # edge like ['A', 'B']
  clean_edge: (edge)->
    parent_id = edge[0]
    child_id = edge[1]

    # 从父节点移除子
    parent = @find_by parent_id
    parent.children = parent.children.filter (id)->
      id != child_id

    parent.edges = parent.edges.filter (e)->
      !(e[0] == edge[0] && e[1] == edge[1])

    # 从子节点移除父
    child = @find_by child_id
    child.parents = child.parents.filter (id)->
      id != parent_id

    child.edges = child.edges.filter (e)->
      !(e[0] == edge[0] && e[1] == edge[1])

    # 移除边
    @_edges = @_edges.filter (e)->
      !(e[0] == edge[0] && e[1] == edge[1])

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

  is_parents_here: (point)->
    for parent_id in point.parents
      return false if !(parent_id of @set)
    return true

  add: (point)->
    @set[point.id] = {}
    @_r(point, point, 1)

  _r: (current_point, point, distance)->
    for parent_id in current_point.parents
      @_merge parent_id, point.id, distance

      @_r @net.find_by(parent_id), point, distance + 1

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