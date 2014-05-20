seajs.config
  base: './js/'
  alias:
    'd3': 'lib/d3-3.4.6.min'
  paths:
    'knowledge': 'dist/knowledge'

seajs.use 'knowledge/graph', (KnowledgeNetGraph)->
  jQuery ->
    if jQuery('body.sample').length
      jQuery.getJSON 'data/js/js.json', (data)->
      # jQuery.getJSON 'fixture/graph.json', (data)->  
        new KnowledgeNetGraph jQuery('.graph-paper'), data