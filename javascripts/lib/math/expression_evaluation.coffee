#= require lib/logger

ttm.define "lib/math/expression_evaluation",
  ['lib/class_mixer', 'lib/object_refinement', 'logger'],
  (class_mixer, object_refinement, logger_builder)->

    logger = logger_builder.build(stringify_objects: false)

    MalformedExpressionError = (message)->
      @name = 'MalformedExpressionError'
      @message = message
      @stack = (new Error()).stack
    MalformedExpressionError.prototype = new Error;

    comps = ttm.lib.math.ExpressionComponentSource.build()
    refinement = object_refinement.build()
    refinement.forType(comps.classes.number,
      {
        eval: ->
          @  # a number returns itself when it evaluates
      });

    refinement.forType(comps.classes.exponentiation,
      {
        eval: (evaluation, pass)->
          return if pass != "exponentiation"
          if @base() && @power()
            base = refinement.refine(@base()).eval().toCalculable()
            power = refinement.refine(@power()).eval().toCalculable()
            logger.info("exponentiation", base, power)
            comps.classes.number.build(value: Math.pow(base, power))
          else
            throw new MalformedExpressionError("Invalid Expression")
      });

    refinement.forType(comps.classes.pi,
      {
        eval: ()->
          comps.classes.number.build(value: Math.PI)
      });

    refinement.forType(comps.classes.addition,
      {
        eval: (evaluation, pass)->
          return if pass != "addition"

          prev = evaluation.previousValue()
          next = evaluation.nextValue()
          if prev && next
            evaluation.handledSurrounding()
            comps.classes.number.build(value: (parseFloat(prev) + parseFloat(next)))
          else
            throw new MalformedExpressionError("Invalid Expression")
      });

    refinement.forType(comps.classes.subtraction,
      {
        eval: (evaluation, pass)->
          return if pass != "addition"

          prev = evaluation.previousValue()
          next = evaluation.nextValue()
          if prev && next
            evaluation.handledSurrounding()
            comps.classes.number.build(value: (parseFloat(prev) - parseFloat(next)))
          else
            throw new MalformedExpressionError("Invalid Expression")
      });


    refinement.forType(comps.classes.multiplication,
      {
        eval: (evaluation, pass)->
          return if pass != "multiplication"
          prev = evaluation.previousValue()
          next = evaluation.nextValue()
          if prev && next
            evaluation.handledSurrounding()
            comps.classes.number.build(value: (parseFloat(prev) * parseFloat(next)))
          else
            throw new MalformedExpressionError("Invalid Expression")
      });



    refinement.forType(comps.classes.division,
      {
        eval: (evaluation, pass)->
          return if pass != "multiplication"
          prev = evaluation.previousValue()
          next = evaluation.nextValue()
          if prev && next
            evaluation.handledSurrounding()
            comps.classes.number.build(value: (parseFloat(prev) / parseFloat(next)))
          else
            throw new MalformedExpressionError("Invalid Expression")

      });

    refinement.forType(comps.classes.expression,
      {
        eval: ->
          expr = @expression
          logger.info("before parenthetical", expr)
          expr = ExpressionEvaluationPass.build(expr).perform("parenthetical")
          logger.info("before exponentiation", expr)
          expr = ExpressionEvaluationPass.build(expr).perform("exponentiation")
          logger.info("before multiplication", expr)
          expr = ExpressionEvaluationPass.build(expr).perform("multiplication")
          logger.info("before addition", expr)
          expr = ExpressionEvaluationPass.build(expr).perform("addition")
          logger.info("before returning", expr)
          _(expr).first()
      });

    class ExpressionEvaluation
      initialize: (@expression, @opts={})->
        @comps = @opts.comps || comps

      resultingExpression: ->
        results = false
        try
          results = @evaluate()
        catch e
          throw e unless e instanceof MalformedExpressionError

        if results
          @comps.classes.expression.build(expression: [results])
        else
          @comps.classes.expression.buildError()

      evaluate: ()->
        refined = refinement.refine(@expression)
        results = refined.eval()

    class_mixer(ExpressionEvaluation)

    class ExpressionEvaluationPass
      initialize: (@expression)->
        @expression_index = -1

      perform: (pass_type)->
        ret = []

        @expression_index = 0
        while @expression.length > @expression_index
          exp = refinement.refine(@expression[@expression_index])
          eval_ret = exp.eval(@, pass_type)
          if eval_ret
            @expression[@expression_index] = eval_ret
          @expression_index += 1

        @expression

      previousValue: ->
        prev = @expression[@expression_index - 1]
        if prev
          prev.value()

      nextValue: ->
        next = @expression[@expression_index + 1]
        if next
          next.value()

      handledPrevious: ->
        @expression.splice(@expression_index - 1, 1)
        @expression_index -= 1

      handledSurrounding: ->
        @handledPrevious()
        @expression.splice(@expression_index + 1, 1)

    class_mixer(ExpressionEvaluationPass)
    return ExpressionEvaluation