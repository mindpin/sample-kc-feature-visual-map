FIXTRUE_G1_JSON_URL = 'fixture/g1.json'
DATA_JS_JSON_URL = 'data/js/js.json'

jQuery ->
  jQuery.ajax
    url: FIXTRUE_G1_JSON_URL
    type: 'GET'
    dataType: 'json'
    success: (json_obj)->
      do_test json_obj

do_test = (json_obj)->
  test 'JSON Object 检查', ->
    console.log json_obj
    ok json_obj['knowledge_points'].length == 8
    ok json_obj['links'].length == 11

  (->
    knet = new KnowledgeNet(json_obj)

    test '对象构建', ->
      console.log knet
      console.log knet.points()
      ok knet.points().length == 8
      ok knet.edges().length == 11

    (->
      n = knet.find_by('A')
      ne = knet.find_by('E')
      
      test '根据 ID 查找节点', ->
        equal n.id, 'A'
        equal n.name, 'A'

      test '节点关联的边-A', ->
        edges = n.edges
        equal edges.length, 2 
        ok edges.indexOf ['A', 'B'] > -1
        ok edges.indexOf ['A', 'C'] > -1

      test '节点关联的边-E', ->
        edges = ne.edges
        equal edges.length, 4
        ok edges.indexOf ['B', 'E'] > -1
        ok edges.indexOf ['D', 'E'] > -1
        ok edges.indexOf ['F', 'E'] > -1
        ok edges.indexOf ['E', 'G'] > -1

      test '子节点和父节点-A', ->
        equal n.parents.length, 0
        equal n.children.length, 2
        ok n.children.indexOf 'B' > -1
        ok n.children.indexOf 'C' > -1
        ok n.children.indexOf 'D' == -1

      test '子节点和父节点-E', ->
        equal ne.parents.length, 3
        ok n.parents.indexOf 'B' > -1
        ok n.parents.indexOf 'D' > -1
        ok n.parents.indexOf 'F' > -1

        equal ne.children.length, 1
        ok n.children.indexOf 'G' > -1
    )()

    test '查找根节点', ->
      roots = knet.roots()
      equal roots.length, 1
      equal roots[0].name, 'A'
  )()

# test "去除根节点", ->
#   ok true, 'ok'