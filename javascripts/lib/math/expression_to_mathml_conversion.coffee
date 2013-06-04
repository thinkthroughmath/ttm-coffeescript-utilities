ttm.define 'lib/math/expression_to_mathml_conversion',
  ['lib/class_mixer', 'lib/object_refinement'],
  (class_mixer, object_refinement)->
    class ExpressionToMathMLConversion
      initialize: (@component_source)->
        @component_source ||= ttm.lib.math.ExpressionComponentSource.build()
        refinement = object_refinement.build()
        refinement.forType(@component_source.classes.number,
          {
            toMathML: ->
              "<mn>#{@value()}</mn>"
          })

        refinement.forType(@component_source.classes.exponentiation,
          {
            toMathML: ->
              base = refinement.refine(@base())
              power = refinement.refine(@power())
              "<msup>#{base.toMathML()}#{power.toMathML()}</msup>"
          });

        refinement.forType(@component_source.classes.expression,
          {
            toMathML: (is_root=false)->
              mathml = ""
              for exp, i in @expression
                mathml += refinement.refine(exp).toMathML()
              if @expression.length > 1
                if is_root
                  "<mrow>#{mathml}</mrow>"
                else
                  "<mfenced>#{mathml}</mfenced>"
              else
                mathml
          });


        refinement.forType(@component_source.classes.equals,
          {
            toMathML: ->
              "<mo>=</mo>"
          });

        refinement.forType(@component_source.classes.addition,
          {
            toMathML: ->
              "<mo>+</mo>"
          });

        refinement.forType(@component_source.classes.multiplication,
          {
            toMathML: ->
              "<mo>&times;</mo>"
          });

        refinement.forType(@component_source.classes.division,
          {
            toMathML: ->
              "<mo>&divide;</mo>"
          });

        refinement.forType(@component_source.classes.subtraction,
          {
            toMathML: ->
              "<mo>-</mo>"
          });

        refinement.forType(@component_source.classes.pi,
          {
            toMathML: ->
              "<mi>&pi;</mi>"
          });

        refinement.forType(@component_source.classes.variable,
          {
            toMathML: ->
              "<mi>#{@name()}</mi>"
          });

        component_source = @component_source
        refinement.forType(@component_source.classes.root,
          {
            isSquareRoot: ->
              degree = @degree()
              if degree.size() == 1
                first = @degree().first()
                first instanceof component_source.classes.number and first.value() == 2
              else
                false

            toMathML: ->
              degree_ml = refinement.refine(@degree()).toMathML();
              radicand_ml = refinement.refine(@radicand()).toMathML();
              if @isSquareRoot()
                "<msqrt>#{radicand_ml}</msqrt>"
              else
                "<mroot>#{radicand_ml}#{degree_ml}</mroot>"
          });

        refinement.forDefault({toMathML: -> throw "toMathML NOT DEFINED FOR #{@unrefined().toString()}"})
        @refinement = refinement

      convert: (expression)->
        @refinement.refine(expression).toMathML(true);

    class_mixer ExpressionToMathMLConversion

    return ExpressionToMathMLConversion
