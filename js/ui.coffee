jQuery ->
  if jQuery('body.sample').length
    jQuery.getJSON 'data/js/js.json', (data)->
    # jQuery.getJSON 'fixture/graph.json', (data)->  
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
    @_links()
    @_nodes()

    @_events()


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
    translate = d3.event.translate
    @__set_text_class scale

    @graph.attr 'transform',
      "translate(#{translate[0] + @offset_x * scale}, #{translate[1]})
       scale(#{scale})"

  __set_text_class: (scale)->
    klass = ['name']
    if scale < 0.7
      klass.push 'hide'

    @name_texts
      .attr 'class', (d)=>
        if d.name is @IMAGINARY_ROOT_NAME
          "iroot " + klass.join ' '
        else
          klass.join ' '

  _tree: ->
    @tree_data = @knet.get_tree_nesting_data()

    imarginay_root =
      name: @IMAGINARY_ROOT_NAME
      children: @tree_data.roots

    @tree = d3.layout.tree()
      .nodeSize [80, 160]

    @nodes = @tree.nodes imarginay_root

    first_node = @tree_data.roots[0]
    @offset_x = - first_node.x + @BASE_OFFSET_X
    @graph.attr 'transform', "translate(#{@offset_x}, 0)"

  _nodes: ->
    @nodes = @graph.selectAll('.node')
      .data @nodes
      .enter()
      .append 'g'
      .attr
        'class': 'node'
        'transform': (d)->
          "translate(#{d.x}, #{d.y})"

    @circles = @nodes.append 'circle'
      .attr
        'r': 15
        'class': (d)=>
          klass = []
          if d.name is @IMAGINARY_ROOT_NAME then klass.push 'iroot'
          if d.depth is 1 then klass.push 'start-point'
          klass.join ' '

    @name_texts = @nodes.append 'text'
      .attr
        'y': 45
        'text-anchor': 'middle'
      .text (d)-> d.name
    @__set_text_class(1)


  _links: ->
    edges = @tree_data.edges

    @links = @graph.selectAll('.link')
      .data edges
      .enter()
      .append 'path'
      .attr
        'd': d3.svg.diagonal()
        'class': (d)=>
          if d.source.name is @IMAGINARY_ROOT_NAME then 'iroot link' else 'link'

  _events: ->
    that = @
    @circles
      .on 'mouseover', (d)->
        # d is data object
        # this is dom
        links = that.links.filter (d1)->
          d1.target.id is d.id

        links.attr
          'class': 'link hover'

      .on 'mouseout', (d)->
        links = that.links.filter (d1)->
          d1.target.id is d.id

        links.attr
          'class': 'link'
