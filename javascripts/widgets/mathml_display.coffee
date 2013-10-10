#= require widgets/base
#= require widgets/mathjax_gateway

class MathMLDisplay
  initialize: (@opts={})->
    @mathml_renderer = @opts.mathml_renderer || ttm.widgets.MathJaxGateway.build()

  render: (opts={})->
    opts = _.extend({}, @opts, opts)
    @figure = $("""
      <figure class='mathml-display #{opts.class}'>
        #{@wrappedMathTag("")}
      </figure>
    """)
    opts.element.append @figure
    @figure

  wrappedMathTag: (content)->
    """
    <math xmlns=\"http://www.w3.org/1998/Math/MathML\">
      #{content}
    </math>
    """

  update: (mathml)->
    @mathml_renderer.renderMathMLInElement(
      @wrappedMathTag(mathml)
      @figure
      => @opts.after_update(@figure)
    )

ttm.class_mixer(MathMLDisplay)



# exports
window.ttm.widgets.MathMLDisplay = MathMLDisplay
