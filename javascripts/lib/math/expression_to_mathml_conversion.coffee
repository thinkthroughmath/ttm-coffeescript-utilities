ttm.define 'lib/math/expression_to_mathml_conversion',
  ['lib/class_mixer', 'lib/math', 'lib/object_refinement'],
  (class_mixer, math, object_refinement)->
    refinement = object_refinement.build()
    refinement.forType(math.components.number,
      {
        toMathML: ->
          "<mn>#{@value()}</mn>"
      })

    refinement.forType(math.components.exponentiation,
      {
        toMathML: ->
          base = refinement.refine(@base())
          power = refinement.refine(@power())
          "<msup>#{base.toMathML()}#{power.toMathML()}</msup>"
      });

    refinement.forType(math.expression,
      {
        convertToMathML: ->
          mathml = ""
          for exp, i in @expression
            mathml += refinement.refine(exp).toMathML(@, i)
          "<mrow>#{mathml}</mrow>"
      });

    class ExpressionToMathMLConversion
      initialize: ()->
      convert: (expression)->
        refinement.refine(expression).convertToMathML();

    class_mixer ExpressionToMathMLConversion

    return ExpressionToMathMLConversion
