class KnowledgeNet
  constructor: (json_obj)->
    @_raw_points = json_obj['knowledge_points']
    @_raw_edges = json_obj['links']

    @_build()


  _build: ->
    @_points_map = {}
    for p in @_raw_points
      @_points_map[p.id] = p
      @_points_map[p.id]['edges'] = []
      @_points_map[p.id]['parents'] = []
      @_points_map[p.id]['children'] = []

    for e in @_raw_edges
      parent_id = e['parent_id']
      child_id = e['child_id']

      @_points_map[parent_id]['edges'].push [parent_id, child_id]
      @_points_map[parent_id]['children'].push child_id

      @_points_map[child_id]['edges'].push [parent_id, child_id]
      @_points_map[child_id]['parents'].push [parent_id]


  points: ->
    if !@_points
      @_points = []
      for key of @_points_map
        @_points.push @_points_map[key]
    @_points


  edges: ->
    @_raw_edges


  find_by: (id)->
    @_points_map[id]


  roots: ->
    if !@_roots
      @_roots = []
      for key of @_points_map
        p = @_points_map[key]
        if p.parents.length == 0
          @_roots.push p
    @_roots

window.KnowledgeNet = KnowledgeNet