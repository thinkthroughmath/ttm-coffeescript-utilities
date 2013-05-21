ttm.define 'widgets/mathml', [], ->
  render = (jquery_element, mathml)->
    elem = MathJax.Hub.getAllJax(jquery_element[0])[0]
    if elem
      MathJax.Hub.Queue(["Text", elem, mathml])
  return render: render
