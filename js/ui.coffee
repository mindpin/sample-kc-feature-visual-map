jQuery ->
  if jQuery('body.sample').length
    jQuery.getJSON 'data/js/js.json', (data)->
      new KnowledgeNetGraph jQuery('.graph-paper'), data

class KnowledgeNetGraph
  constructor: (@$elm, @data)->
    @SCALE = [0.25, 2]
    @IMAGINARY_ROOT_NAME = 'IROOT'
    @BASE_OFFSET_X = 300

    @offset_x = 0
    @offset_y = 0

    @knet = new KnowledgeNet @data

    @draw()


  draw: ->
    @_svg()
    @_tree()


  _svg: ->
    zoom_behavior = d3.behavior.zoom()
      .scaleExtent @SCALE
      .on 'zoom', @__zoom

    @svg = d3.select @$elm[0]
      .append 'svg'
        .attr 'class', 'knsvg'
        .call zoom_behavior
    
    @graph = @svg.append('g')

  __zoom: =>
    scale = d3.event.scale
    @__set_text_class scale

    translate = d3.event.translate

    @graph.attr 'transform',
      "translate(#{translate[0] + @offset_x * scale}, #{translate[1]})
       scale(#{scale})"

  __set_text_class: (scale)->
    klass = ['name']
    if scale < 0.8
      klass.push 'hide'

    @name_text
      .attr 'class', (d)=>
        if d.name is @IMAGINARY_ROOT_NAME
          "iroot " + klass.join ' '
        else
          klass.join ' '

  _tree: ->
    tree_data = @knet.get_tree_nesting_data()

    obj =
      name: @IMAGINARY_ROOT_NAME
      children: tree_data

    # ------------
    # D3

    tree = d3.layout.tree()
      .nodeSize [80, 120]
      .separation (a, b)->
        if a.parent == b.parent then 1 else 2;

    diagonal = d3.svg.diagonal()
      .projection (d)->
        [d.x, d.y]

    nodes = tree.nodes obj
    links = tree.links nodes

    first_node = tree_data[0]
    @offset_x = - first_node.x + @BASE_OFFSET_X
    @graph.attr 'transform', "translate(#{@offset_x}, 0)"



    node_enter = @graph.selectAll('.node')
      .data nodes
      .enter()
      .append 'g'
      .attr 'class', 'node'
      .attr 'transform', (d)->
        "translate(#{d.x}, #{d.y})"

    @circle = node_enter.append 'circle'
      .attr 'r', 15
      .attr 'class', (d)=>
        klass = []
        if d.depth is 1 then klass.push 'start-point'
        if d.name is @IMAGINARY_ROOT_NAME then klass.push 'iroot'
        klass.join ' '

    @name_text = node_enter.append 'text'
      .attr 'dy', 45
      .attr 'text-anchor', 'middle'
      .text (d)-> d.name
    @__set_text_class(1)

    @graph.selectAll('.link')
      .data links
      .enter()
      .insert 'path', 'g'
      .attr 'd', diagonal
      .attr 'class', (d)=>
        if d.source.name is @IMAGINARY_ROOT_NAME then 'iroot link' else 'link'
