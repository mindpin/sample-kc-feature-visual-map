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

    [@NODE_WIDTH, @NODE_HEIGHT] = [150, 180]

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

    @_bar()
    @_bar_events()

    @_init_pos()

  _bar: ->
    @__bar_zoom()
    @__bar_count()

  __bar_zoom: ->
    @$bar = jQuery '<div></div>'
      .addClass 'bar'
      .appendTo @$paper

    @$scale = jQuery '<div></div>'
      .addClass 'scale'
      .text '100 %'
      .appendTo @$bar

    @$scale_minus = jQuery '<div></div>'
      .addClass 'scale-minus'
      .html "<i class='fa fa-minus'></i>"
      .appendTo @$bar

    @$scale_plus = jQuery '<div></div>'
      .addClass 'scale-plus'
      .html "<i class='fa fa-plus'></i>"
      .appendTo @$bar

  __bar_count: ->
    start_count = @knet.roots().length
    common_count = @knet.points().length - start_count

    @$start_point_count = jQuery '<div></div>'
      .addClass 'start-points-count'
      .html """
              <span>起始知识点</span>
              <span class='count'>#{start_count}</span>
            """
      .appendTo @$bar

    @$start_point_count = jQuery '<div></div>'
      .addClass 'common-points-count'
      .html """
              <span>一般知识点</span>
              <span class='count'>#{common_count}</span>
            """
      .appendTo @$bar

    @$count_pie = jQuery '<div></div>'
      .addClass 'count-pie'
      .appendTo @$bar

    w = 150
    h = 150
    outer_radius = w / 2
    inner_radius = w / 2.666
    arc = d3.svg.arc()
      .innerRadius(inner_radius)
      .outerRadius(outer_radius)

    svg = d3.select @$count_pie[0]
      .append 'svg'
      .attr
        'width': w
        'height': h
      .style
        'margin': '25px 0 0 25px'

    arcs = svg.selectAll 'g.arc'
      .data d3.layout.pie()([start_count, common_count])
      .enter()
      .append 'g'
      .attr
        'class': 'arc'
        'transform': "translate(#{outer_radius}, #{outer_radius})"

    colors = ['#FFB43B', '#65B2EF']

    arcs.append 'path'
      .attr
        'fill': (d, i)-> colors[i]
        'd': arc


  _bar_events: ->
    @$scale_minus.on 'click', @__zoomout
    @$scale_plus.on 'click', @__zoomin

  # 缩小
  __zoomout: =>
    scale = @zoom_behavior.scale()
    
    new_scale = 
    if scale > 1.414 then 1.414
    else if scale > 1     then 1
    else if scale > 0.707 then 0.707
    else if scale > 0.5   then 0.5
    else if scale > 0.354 then 0.354
    else 0.25

    @zoom_transition = true
    @zoom_behavior.scale(new_scale).event @svg

  # 放大
  __zoomin: =>
    scale = @zoom_behavior.scale()
    
    new_scale = 
    if scale < 0.354      then 0.354
    else if scale < 0.5   then 0.5
    else if scale < 0.707 then 0.707
    else if scale < 1     then 1
    else if scale < 1.414 then 1.414
    else 2

    @zoom_transition = true
    @zoom_behavior.scale(new_scale).event @svg

  _svg: ->
    @zoom_behavior = d3.behavior.zoom()
      .scaleExtent @SCALE
      .center [@$elm.width() / 2, @$elm.height() / 2]
      .on 'zoom', @__zoom

    @svg = d3.select @$paper[0]
      .append 'svg'
        .attr 'class', 'knsvg'
        .call @zoom_behavior
        .on 'dblclick.zoom', null

    @graph = @svg.append('g')

  __zoom: =>
    scale = @zoom_behavior.scale()
    translate = @zoom_behavior.translate()
    @__set_text_class scale

    g = if @zoom_transition then @graph.transition() else @graph
    @zoom_transition = false

    g
      .attr 'transform',
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
      .each (d, i)->
        for str, j in KnowledgeNet.break_text(d.name)
          dy = if j is 0 then '0' else '1.5em'
          d3.select(this).append 'tspan'
            .attr
              'x': 0
              'dy': dy
            .text str

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

  _init_pos: ->
    first_node = @tree_data.roots[0]
    @offset_x = - first_node.x + @$elm.width() / 3
    
    @zoom_behavior.event @svg

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
