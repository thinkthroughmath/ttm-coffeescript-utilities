#= require lib
#= require widgets/base

class MathJaxGateway
  renderMathMLInElement: (mathml, jquery_element)->
    elem = MathJax.Hub.getAllJax(jquery_element[0])[0]
    if elem
      MathJax.Hub.Queue(["Text", elem, mathml])

window.ttm.widgets.MathJaxGateway = ttm.class_mixer(MathJaxGateway)

