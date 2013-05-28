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
        toMathML: ->
          mathml = ""
          for exp, i in @expression
            mathml += refinement.refine(exp).toMathML(@, i)
          if @expression.length > 1
            "<mrow>#{mathml}</mrow>"
          else
            mathml
      });


    refinement.forType(math.components.equals,
      {
        toMathML: ->
          "<mo>=</mo>"
      });

    refinement.forType(math.components.addition,
      {
        toMathML: ->
          "<mo>+</mo>"
      });

    refinement.forType(math.components.multiplication,
      {
        toMathML: ->
          "<mo>&times;</mo>"
      });

    refinement.forType(math.components.division,
      {
        toMathML: ->
          "<mo>&divide;</mo>"
      });

    refinement.forType(math.components.subtraction,
      {
        toMathML: ->
          "<mo>-</mo>"
      });

    class ExpressionToMathMLConversion
      initialize: ()->
      convert: (expression)->
        refinement.refine(expression).toMathML();

    class_mixer ExpressionToMathMLConversion

    return ExpressionToMathMLConversion
