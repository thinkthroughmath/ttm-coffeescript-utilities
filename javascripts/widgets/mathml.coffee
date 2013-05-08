ttm.define 'widgets/mathml', [], ->
  render = (element)->
    MathJax.Hub.Queue(["Typeset",MathJax.Hub,element]);
  return render: render
