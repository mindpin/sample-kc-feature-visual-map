jQuery ->
  if jQuery('body.sample').length
    jQuery.getJSON 'data/js/js.json', (data)->
      new KnowledgeNetGraph jQuery('.graph-paper'), data

class KnowledgeNetGraph
  constructor: (@$elm, @data)->
    @SCALE = [0.25, 2]

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
    @__toggle_text_by_scale scale

    translate = d3.event.translate

    @graph.attr 'transform',
      "translate(#{translate[0] + @offset_x * scale}, #{translate[1]})
       scale(#{scale})"

  __toggle_text_by_scale: (scale)->
    if scale < 0.8
      @text.attr 'class', 'hide'
    else
      @text.attr 'class', null

  _tree: ->
    tree_data = @knet.get_tree_nesting_data()

    obj = {
      name:'ROOT'
      children: tree_data
    }

    # ------------
    # D3

    tree = d3.layout.tree()
      .nodeSize [80, 100]
      .separation (a, b)->
        if a.parent == b.parent then 1 else 2;

    diagonal = d3.svg.diagonal()
      .projection (d)->
        [d.x, d.y]

    nodes = tree.nodes obj
    links = tree.links nodes

    first_node = tree_data[0]
    @offset_x = - first_node.x + 300
    @graph.attr 'transform', "translate(#{@offset_x}, 0)"



    node_enter = @graph.selectAll('.node')
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

    @graph.selectAll('.link')
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