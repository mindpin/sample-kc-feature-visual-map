jQuery ->
  if jQuery('body.sample').length
    jQuery.getJSON 'data/js/js.json', (data)->
    # jQuery.getJSON 'fixture/graph.json', (data)->  
      new KnowledgeNetGraph jQuery('.graph-paper'), data

class Zoomer
  constructor: (@host)->
    @SCALE = [0.25, 2]

    @scale = 1
    @zoom_transition = false

    @viewport_w = @host.$elm.width()
    @viewport_h = @host.$elm.height()

    @center_x = @viewport_w / 2
    @center_y = @viewport_h / 2

    @zoom_behavior = d3.behavior.zoom()
      .scaleExtent @SCALE
      .center [@center_x, @center_y]
      .on 'zoom', @zoomed

  # 缩小
  zoomout: =>
    scale = @zoom_behavior.scale()
    
    new_scale = 
    if scale > 1.414 then 1.414
    else if scale > 1     then 1
    else if scale > 0.707 then 0.707
    else if scale > 0.5   then 0.5
    else if scale > 0.354 then 0.354
    else 0.25

    @zoom_transition = true
    @scaleto new_scale

  # 放大
  zoomin: =>
    scale = @zoom_behavior.scale()
    
    new_scale = 
    if scale < 0.354      then 0.354
    else if scale < 0.5   then 0.5
    else if scale < 0.707 then 0.707
    else if scale < 1     then 1
    else if scale < 1.414 then 1.414
    else 2

    @zoom_transition = true
    @scaleto new_scale

  zoomed: =>
    @scale     = @zoom_behavior.scale()
    @translate = @zoom_behavior.translate()

    console.log @scale, @translate

    @host.deal_zoom(@scale, @translate, @zoom_transition)
    @zoom_transition = false

  scaleto: (new_scale)->
    scale     = @zoom_behavior.scale()
    translate = @zoom_behavior.translate()

    # 注释不要删除噢 ~~~~~
    # 根据以下公式换算
    # translate[0] = [ox * scale + (1 - scale) / 2 * w]
    # translate[1] = [oy * scale + (1 - scale) / 2 * h]
    # -->
    # ox = (translate[0] - (1 - scale) / 2 * w) / scale
    # ox = translate[0] / scale - (1 - scale) / 2 * w / scale
    # ox = translate[0] / scale - (w / scale - w) / 2
    # ox = translate[0] / scale - w / 2 / scale + w / 2
    # ox = (translate[0] - w / 2) / scale + w / 2

    # -->
    # otx = (translate[0] - @center_x) / scale + @center_x
    # oty = (translate[1] - @center_y) / scale + @center_y

    # -->
    # tn = (1 - new_scale) / 2
    # tx = tn * @viewport_w
    # ty = tn * @viewport_h

    # tx = @center_x - @center_x * new_scale
    # ty = @center_y - @center_y * new_scale

    # t0 = otx * scale
    # t1 = oty * scale

    # t0 = translate[0] + @center_x * (scale - 1)
    # t1 = translate[1] + @center_y * (scale - 1)

    # --> 最终导出！

    new_translate = [
      translate[0] + @center_x * scale - @center_x * new_scale
      translate[1] + @center_y * scale - @center_y * new_scale
    ]

    @zoom_behavior
      .scale new_scale
      .translate new_translate
      .event @host.svg


class KnowledgeNetGraph
  constructor: (@$elm, @data)->
    @$paper = jQuery '<div></div>'
      .addClass 'knowledge-net-paper'
      .appendTo @$elm

    @CIRCLE_RADIUS = 15

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


  deal_zoom: (scale, translate, transition)->
    g = 
      if transition
      then @graph.transition() 
      else @graph

    tx = translate[0] + @offset_x * scale
    ty = translate[1]

    g.attr 'transform', 
      "translate(#{tx}, #{ty})scale(#{scale})"

    @__set_text_class scale
    @$scale.text "#{Math.round(scale * 100)} %"
    # bugfix for phone
    @hide_point_info()


  _bar: ->
    @__bar_zoom()
    @__bar_count()
    @__bar_point_info()

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

  __bar_point_info: ->
    @$point_info = jQuery '<div></div>'
      .addClass 'point-info'
      .html """
              <h3>创建数组</h3>
              <p>允许的字符的集合</p>
              <div>
                <span class='depend'>前置知识点：</span>
                <span class='depend-count'></span>
              </div>
            """
      .appendTo @$paper

  show_point_info: (point, elm, direct_depend_count, indirect_depend_count)->
    name = point.name
    desc = point.desc

    @$point_info.find('h3').html name
    @$point_info.find('p').html desc

    dc = direct_depend_count + indirect_depend_count

    if dc is 0
      @$point_info.find('span.depend').hide()
      @$point_info.find('span.depend-count')
        .html '这是起始知识点'
    else
      @$point_info.find('span.depend').show()
      @$point_info.find('span.depend-count')
        .html dc

    $e = jQuery(elm)

    o = $e.offset()
    o1 = @$paper.offset()

    l = o.left - o1.left + @CIRCLE_RADIUS * 2 * @zoomer.scale + 30
    t = o.top - o1.top + @CIRCLE_RADIUS * @zoomer.scale - 30

    @$point_info
      .addClass 'show'
      .css
        'left': l
        'top': t

  hide_point_info: ->
    @$point_info.removeClass 'show'


  _bar_events: ->
    @$scale_minus.on 'click', @zoomer.zoomout
    @$scale_plus.on 'click', @zoomer.zoomin

  _svg: ->
    @zoomer = new Zoomer @

    @svg = d3.select @$paper[0]
      .append 'svg'
        .attr 'class', 'knsvg'
        .call @zoomer.zoom_behavior
        .on 'dblclick.zoom', null

    @graph = @svg.append('g')


  __set_text_class: (scale)->
    klass = ['name']
    if scale < 0.75
      klass.push 'hide'

    @name_texts
      .attr 
        'class': klass.join ' '

  _tree: ->
    @tree_data = @knet.get_tree_nesting_data()

    imarginay_root =
      children: @tree_data.roots

    tree = d3.layout.tree()
      .nodeSize [@NODE_WIDTH, @NODE_HEIGHT]

    @dataset_nodes = tree.nodes(imarginay_root)[1..-1]
    @dataset_edges = @tree_data.edges

  _links: ->
    @links = @graph.selectAll('.link')
      .data @dataset_edges
      .enter()
      .append 'path'
      .attr
        'd': d3.svg.diagonal()
        'class': 'link'

  _nodes: ->
    @nodes = @graph.selectAll('.node')
      .data @dataset_nodes
      .enter()
      .append 'g'
      .attr
        'class': 'node'
        'transform': (d)->
          "translate(#{d.x}, #{d.y})"

    @circles = @nodes.append 'circle'
      .attr
        'r': @CIRCLE_RADIUS
        'class': (d)=>
          klass = []
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


  _init_pos: ->
    first_node = @tree_data.roots[0]
    @offset_x = - first_node.x + @$elm.width() * 0.4

    @zoomer.zoom_behavior
      .scale 0.75
      .event @svg

  _events: ->
    that = @
    @circles
      .on 'mouseover', (d, i)->
        # d is data object
        # this is dom

        # 标记直接依赖节点
        links = that.links.filter (link)->
          link.target.id is d.id

        links.attr
          'class': 'link direct-depend'

        # 标记间接依赖节点
        d0 = that.knet.find_by d.id
        stack = d0.parents.map (id)-> that.knet.find_by id
        depend_point_ids = []

        while stack.length > 0
          dr = stack.shift()
          for id in dr.parents
            parent = that.knet.find_by id
            stack.push parent
            depend_point_ids.push parent.id unless parent.id in depend_point_ids

          that.links
            .filter (link)->
              link.target.id is dr.id
            .attr
              'class': 'link depend'

        # 高亮间接依赖节点
        that.circles
          .filter (c)->
            c.id in depend_point_ids or c.id in d0.parents
          .attr
            'class': (d)->
              return 'start-point' if d.depth is 1
              return 'depend'

        direct_depend_count = links[0].length

        that.show_point_info(d, this, direct_depend_count, depend_point_ids.length)

      .on 'mouseout', (d)->
        that.links.attr
          'class': 'link'

        that.circles.attr
          'class': (d)->
            return 'start-point' if d.depth is 1

        that.hide_point_info()

      .on 'click', (d)->
        # console.log jQuery(this).offset()
