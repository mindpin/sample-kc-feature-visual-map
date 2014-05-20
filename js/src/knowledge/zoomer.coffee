define (require, exports, module)->
  require 'd3'

  class Zoomer
    constructor: (@host)->
      @SCALE_EXTENT = [0.25, 2]

      @scale = 1
      @zoom_transition = false

      @viewport_w = @host.$elm.width()
      @viewport_h = @host.$elm.height()

      @center_x = @viewport_w / 2
      @center_y = @viewport_h / 2

      @zoom_behavior = d3.behavior.zoom()
        .scaleExtent @SCALE_EXTENT
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