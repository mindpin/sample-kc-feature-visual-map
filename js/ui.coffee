jQuery ->
  if jQuery('body.sample').length
    jQuery.getJSON 'data/js/js.json', (data)->
    # jQuery.getJSON 'fixture/graph.json', (data)->  
      new KnowledgeNetGraph jQuery('.graph-paper'), data

class KnowledgeNetGraph
  constructor: (@$elm, @data)->
    @$paper = jQuery '<div></div>'
      .addClass 'knowledge-net-paper'
      .appendTo @$elm

    @SCALE = [0.25, 2]
    @IMAGINARY_ROOT_NAME = 'IROOT'
    @BASE_OFFSET_X = 300

    [@NODE_WIDTH, @NODE_HEIGHT] = [150, 180]

    @offset_x = 0
    @offset_y = 0

    @knet = new KnowledgeNet @data

    @draw()


  draw: ->
    @_bar()

    @_svg()
    @_tree()
    @_links()
    @_nodes()

    @_events()

  _bar: ->
    @$bar = jQuery '<div></div>'
      .addClass 'bar'
      .appendTo @$paper

    @$scale = jQuery '<div></div>'
      .addClass 'scale'
      .text '100 %'
      .appendTo @$bar

  _svg: ->
    zoom_behavior = d3.behavior.zoom()
      .scaleExtent @SCALE
      .on 'zoom', @__zoom

    @svg = d3.select @$paper[0]
      .append 'svg'
        .attr 'class', 'knsvg'
        .call zoom_behavior
        .on 'dblclick.zoom', null

    @graph = @svg.append('g')

  __zoom: =>
    scale = d3.event.scale
    translate = d3.event.translate
    @__set_text_class scale

    @graph.attr 'transform',
      "translate(#{translate[0] + @offset_x * scale}, #{translate[1]})
       scale(#{scale})"

    @$scale.text "#{Math.round(scale * 100)} %"

  __set_text_class: (scale)->
    klass = ['name']
    if scale < 0.75
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
      .nodeSize [@NODE_WIDTH, @NODE_HEIGHT]

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

    console.log @name_texts

    that = @
    @name_texts.attr '', (d, i)->
      sub = that.name_texts.filter (d1, j)-> i is j

      for str, j in KnowledgeNet.break_text(d.name)
        dy = if j is 0 then '0' else '1.5em'

        sub
          .append 'tspan'
          .attr
            'x': 0
            'dy': dy
          .text str

      null

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
      .on 'mouseover', (d, i)->
        # d is data object
        # this is dom
        links = that.links.filter (d1)->
          d1.target.id is d.id

        links.attr
          'class': 'link hover'

        # offset = jQuery(this).offset()
        # console.log d.name, d.desc

      .on 'mouseout', (d)->
        links = that.links.filter (d1)->
          d1.target.id is d.id

        links.attr
          'class': 'link'

      .on 'click', (d)->
        # console.log jQuery(this).offset()
