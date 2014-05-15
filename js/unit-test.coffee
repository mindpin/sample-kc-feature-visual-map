FIXTRUE_GRAPH_JSON_URL = 'fixture/graph.json'
DATA_JS_JSON_URL = 'data/js/js.json'

load_json = (url, func)->
  jQuery.ajax
    url: url
    type: 'GET'
    dataType: 'json'
    success: (obj)->
      func(obj)

jQuery ->
  load_json FIXTRUE_GRAPH_JSON_URL, (obj)->
    do_test obj['G1'], obj['G2'], obj['G3'], obj['G4']

  load_json DATA_JS_JSON_URL, (obj)->
    js_net = new KnowledgeNet(obj)

    test '查找多余边-JS', ->
      redundant_edges = js_net.get_redundant_edges()
      deepEqual redundant_edges.sort(), [
        ['n16', 'n89']
      ]

do_test = (g1_obj, g2_obj, g3_obj, g4_obj)->
  test 'JSON Object 检查', ->
    ok g1_obj['points'].length == 8
    ok g1_obj['edges'].length == 11

  # 数据，属性
  (->
    knet = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)

    test '对象构建', ->
      ok knet.points().length == 8
      ok knet.edges().length == 11

    (->
      n = knet.find_by('A')
      ne = knet.find_by('E')
      
      test '根据 ID 查找节点', ->
        equal n.id, 'A'
        equal n.name, 'A'

      test '节点关联的边-G1-A', ->
        edges = n.edges
        equal edges.length, 2 
        deepEqual edges.sort(), [['A', 'B'], ['A', 'C']]

      test '节点关联的边-G1-E', ->
        edges = ne.edges
        equal edges.length, 4
        deepEqual edges.sort(), [['B', 'E'], ['D', 'E'], ['E', 'G'], ['F', 'E']]

      test '子节点和父节点-G1-A', ->
        equal n.parents.length, 0
        equal n.children.length, 2
        deepEqual n.children.sort(), ['B', 'C']

      test '子节点和父节点-G1-E', ->
        equal ne.parents.length, 3
        deepEqual ne.parents.sort(), ['B', 'D', 'F']

        equal ne.children.length, 1
        deepEqual ne.children, ['G']
    )()

    test '查找根节点-G1', ->
      roots = knet.roots()
      equal roots.length, 1
      ok knet.is_root 'A'

    test '查找根节点-G2', ->
      roots = knet2.roots()
      equal roots.length, 3
      ok knet2.is_root 'I'
      ok knet2.is_root 'J'
      ok knet2.is_root 'O'
      ok !knet2.is_root 'P'
  )()

  # 多余边查找算法
  (->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)

    test '查找多余边-G1', ->
      redundant_edges = knet1.get_redundant_edges()
      deepEqual redundant_edges.sort(), [
        ['B', 'E'], ['D', 'H'], ['F', 'H']
      ]

    test '查找多余边-G2', ->
      redundant_edges = knet2.get_redundant_edges()
      deepEqual redundant_edges.sort(), []

    test '查找多余边-G3', ->
      redundant_edges = knet3.get_redundant_edges()
      deepEqual redundant_edges.sort(), [
        ['A', 'C'], ['A', 'D'], ['B', 'E'], ['C', 'F']
      ]

    test '剔除多余边-G1', ->
      c = knet1.edges().length
      knet1.clean_redundant_edges()
      equal knet1.edges().length, c - 3 

      deepEqual knet1.find_by('B').children, ['D']
      deepEqual knet1.find_by('E').parents, ['D', 'F']

    test '剔除多余边-G2', ->
      c = knet2.edges().length
      knet2.clean_redundant_edges()
      equal knet2.edges().length, c 

    test '剔除多余边-G3', ->
      deepEqual knet3.find_by('C').edges, [
        ['A', 'C'],
        ['B', 'C'], 
        ['C', 'D'],
        ['C', 'F']
      ]

      c = knet3.edges().length
      knet3.clean_redundant_edges()
      equal knet3.edges().length, c - 4 

      deepEqual knet3.find_by('A').children, ['B']
      deepEqual knet3.find_by('A').edges, [['A', 'B']]

      deepEqual knet3.find_by('B').children, ['C']
      deepEqual knet3.find_by('B').edges, [['A', 'B'], ['B', 'C']]

      deepEqual knet3.find_by('C').children, ['D']
      deepEqual knet3.find_by('C').edges, [['B', 'C'], ['C', 'D']]

      deepEqual knet3.find_by('D').children, ['E']
      deepEqual knet3.find_by('E').children, ['F']
  )()

  # 多余边查找算法用到的函数
  (->
    knet = new KnowledgeNet(g1_obj)
    ds = new KnowledgeNet.DistanceSet knet

    test 'set#is_parents_here', ->
      ds.set = {}
      p = {id:'A', parents:[]}
      ok ds.is_parents_here p

    test 'set#is_parents_here', ->
      ds.set = {
        'A':{}
        'B':{}
      }
      p = {id:'C', parents:['A']}
      ok ds.is_parents_here p

    test 'set#is_parents_here', ->
      ds.set = {
        'A':{}
        'B':{}
        'C':{}
      }
      p1 = {id:'D', parents:['A', 'B', 'C']}
      p2 = {id:'E', parents:['C', 'D']}
      ok ds.is_parents_here p1
      ok !ds.is_parents_here p2
  )()

  # 多余边查找算法用到的函数
  (->
    knet = new KnowledgeNet(g1_obj)
    ds = new KnowledgeNet.DistanceSet knet

    test 'set#add A', ->
      ds.add knet.find_by('A')
      deepEqual ds.set, {
        'A':{}
      }

    test 'set#add B', ->
      ds.add knet.find_by('B')
      deepEqual ds.set, {
        'A':{'B':1}
        'B':{}
      }

    test 'set#add C', ->
      ds.add knet.find_by('C')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1}
        'B':{}
        'C':{}
      }

    test 'set#add D', ->
      ds.add knet.find_by('D')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1, 'D':2}
        'B':{'D':1}
        'C':{}
        'D':{}
      }

    test 'set#add F', ->
      ds.add knet.find_by('F')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1, 'D':2, 'F':2}
        'B':{'D':1}
        'C':{'F':1}
        'D':{}
        'F':{}
      }

    test 'set#add E', ->
      ds.add knet.find_by('E')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1, 'D':2, 'F':2, 'E':3}
        'B':{'D':1, 'E':2}
        'C':{'F':1, 'E':2}
        'D':{'E':1}
        'F':{'E':1}
        'E':{}
      }
      deepEqual ds.redundant_edges, [
        ['B', 'E']
      ]

    test 'set#add G', ->
      ds.add knet.find_by('G')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1, 'D':2, 'F':2, 'E':3, 'G':4}
        'B':{'D':1, 'E':2, 'G':3}
        'C':{'F':1, 'E':2, 'G':3}
        'D':{'E':1, 'G':2}
        'F':{'E':1, 'G':2}
        'E':{'G':1}
        'G':{}
      }
      deepEqual ds.redundant_edges, [
        ['B', 'E']
      ]

    test 'set#add H', ->
      ds.add knet.find_by('H')
      deepEqual ds.set, {
        'A':{'B':1, 'C':1, 'D':2, 'F':2, 'E':3, 'G':4, 'H':5}
        'B':{'D':1, 'E':2, 'G':3, 'H':4}
        'C':{'F':1, 'E':2, 'G':3, 'H':4}
        'D':{'E':1, 'G':2, 'H':3}
        'F':{'E':1, 'G':2, 'H':3}
        'E':{'G':1, 'H':2}
        'G':{'H':1}
        'H':{}
      }
      deepEqual ds.redundant_edges.sort(), [
        ['B', 'E'], ['D', 'H'], ['F', 'H']
      ]
  )()

  # 最优化节点深度
  (->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)
    knet4 = new KnowledgeNet(g4_obj)

    test 'g1 deeps', ->
      deepEqual knet1.get_deeps(), {
        'A':1, 
        'B':2, 'C':2
        'D':3, 'F':3
        'E':4
        'G':5
        'H':6
      }

    test 'g2 deeps', ->
      deepEqual knet2.get_deeps(), {
        'I':1, 'J':1 
        'K':2,
        'L':3, 'M':3
        'N':4

        'O':1
        'P':2
      }

    test 'g3 deeps', ->
      deepEqual knet3.get_deeps(), {
        'A':1, 'B':2, 'C':3, 'D':4, 'E':5, 'F':6
      }

    test 'g4 deeps', ->
      deepEqual knet4.get_deeps(), {
        'A':1, 
        'B':2, 'D':2
        'C':3, 
        'E':4, 
        'F':5
        'G':1
      }
  )()

  # 生成树构建算法
  (->
    knet1 = new KnowledgeNet(g1_obj)
    knet2 = new KnowledgeNet(g2_obj)
    knet3 = new KnowledgeNet(g3_obj)
    knet4 = new KnowledgeNet(g4_obj)

    test 'g4 nodes count', ->
      equal knet4.points().length, 7

    test 'get g4 TREE', ->
      tree_data = knet4.get_tree_data()

      deepEqual tree_data['points'].sort(), ['A', 'B', 'C', 'D', 'E', 'F', 'G']
      deepEqual tree_data['edges'].sort(), [
        ['A', 'B'], ['A', 'D']
        ['B', 'C'], ['C', 'E']
        ['E', 'F'],
      ]

    test 'get g1 TREE', ->
      tree_data = knet1.get_tree_data()
      deepEqual tree_data['edges'].sort(), [
        ['A', 'B'], ['A', 'C']
        ['B', 'D'], ['C', 'F']
        ['E', 'G'], ['F', 'E'], # ['D', 'E'] // 生成方式不唯一
        ['G', 'H']
      ]
  )()

  # test '环路检查'