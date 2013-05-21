#= require almond_wrapper
#= require lib/math/expression_evaluation

ttm.define "lib/math/expression_manipulation",
  ["lib/class_mixer", 'lib/math/expression_components',
    'lib/math/expression_evaluation', 'lib/object_refinement', 'logger'],
  (class_mixer, comps, expression_evaluation, object_refinement, logger_builder)->

    logger = logger_builder.build(stringify_objects: false)

    class ExpressionManipulation
      evaluate: (exp)->
        expression_evaluation.build(exp).resultingExpression()

      value: (exp)->
        result = expression_evaluation.build(exp).evaluate()
        if result then result.value() else 0

    class Calculate extends ExpressionManipulation
      invoke: (expression)->
        @evaluate(expression)
    class_mixer(Calculate)

    class Square extends ExpressionManipulation
      invoke: (expression)->
        val = @value(expression)
        comps.expression.build expression: [comps.number.build(value: val*val)]
    class_mixer(Square)

    class AppendDecimal

      onFinalExpression: (expression)->
        last = expression.last()
        if last instanceof comps.number
          new_last = last.clone()
          new_last = new_last.futureAsDecimal()
          expression.replaceLast(new_last)
        else
          new_last = comps.number.build(value: 0)
          new_last = new_last.futureAsDecimal()
          expression.append(new_last)

      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build((expr)=> @onFinalExpression(expr)).
          invokeOrDefault(expression)

    class_mixer(AppendDecimal)

    class AppendNumber
      initialize: (@opts)->
        @val = @opts.value

      onFinalExpression: (expression)->
        expression = _ImplicitMultiplication.build().onNeitherOperatorNorNumber(expression)
        last = expression.last()
        number_with_this_val = comps.number.build(value: @val)
        if last && last instanceof comps.number
          new_last = last.concatenate(@val)
          expression.replaceLast(new_last)
        else if last && last instanceof comps.exponentiation
          power = last.power()
          if power instanceof comps.blank
            new_last = last.updatePower(number_with_this_val)
          else
            new_last = last.updatePower(power.concatenate(@val))
          expression.replaceLast(new_last)
        else
          expression.append(number_with_this_val)

      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build((expr)=> @onFinalExpression(expr)).
          invokeOrDefault(expression)

    class_mixer(AppendNumber)

    class ExponentiateLast
      initialize: (@opts={})->
      invoke: (expression)->
        last = expression.last()

        # in the first case, our base case comes
        # from the contents of a previous part of the expression
        if it = last.preceedingSubexpression()
          base = it

        # if the previous element is an operator but has no sub-expression,
        # then we are dropping the operator and use the number prior to the operator
        else if last.isOperator()
          expression = expression.withoutLast() #remove useless operator
          base = expression.last()

        # otherwise, our base is just the number before
        else
          base = expression.last()

        power = if @opts.power then comps.number.build(value: @opts.power) else comps.blank.build()

        expression.replaceLast(
          comps.exponentiation.build(base: base, power: power))

    class_mixer(ExponentiateLast)


    class AppendMultiplication
      appendAction: (expression)->
        _OverrideIfOperatorOrAppend.build(expression).with comps.multiplication.build()

      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build((expr)=> @appendAction(expr)).
          invokeOrDefault(expression)

    class_mixer(AppendMultiplication)


    class AppendDivision
      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build((expr)=>
          _OverrideIfOperatorOrAppend.build(expr).with comps.division.build()).
          invokeOrDefault(expression)
    class_mixer(AppendDivision)


    class AppendAddition
      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build(
          (expression)->
            _OverrideIfOperatorOrAppend.build(expression).with comps.addition.build()
          ).invokeOrDefault(expression)

    class_mixer(AppendAddition)


    class AppendSubtraction
      invoke: (expression)->
        _FinalOpenSubExpressionApplcation.build(
          (expression)->
            _OverrideIfOperatorOrAppend.build(expression).with comps.subtraction.build()
          ).invokeOrDefault(expression)

    class_mixer(AppendSubtraction)

    class Negation
      invoke: (expression)->
        last = expression.last()
        if last
            expression.replaceLast(last.negated())
        else
          expression

    class_mixer(Negation)

    class OpenSub
      invoke: (expression)->
        _ImplicitMultiplication.build().
          onNumeric(expression).
          append(comps.expression.build().open())
    class_mixer(OpenSub)

    class _FinalOpenSubExpressionApplcation
      initialize: (@action)->
        @found = false

      invoke: (expr)->
        subexp = @nextSubExpression(expr)
        if subexp
          subexp = @invoke(subexp)
        if @found # the child element below me was updated
          @updateWithNewSubexp(expr, subexp)
        else if expr instanceof comps.expression and expr.isOpen()
          @found = true
          @action expr
        else # not closable, not handled, return
          expr

      wasFound: -> @found

      updateWithNewSubexp: (expr, subexp)->
        if expr instanceof comps.expression
          expr.replaceLast(subexp)
        else if expr instanceof comps.exponentiation
          expr.updatePower(subexp)

      nextSubExpression: (expr)->
        if expr instanceof comps.expression
          expr.last()
        else if expr instanceof comps.exponentiation
          expr.power()
        else false

      invokeOrDefault: (expr)->
        result = @invoke(expr)
        if @wasFound()
          result
        else
          @action(expr)

    class_mixer(_FinalOpenSubExpressionApplcation)


    class CloseSub
      initialize: ->
        @handled = false
      invoke: (expression)->
        logger.info("CloseSub#invoke")
        _FinalOpenSubExpressionApplcation.build(
          (expression)-> expression.close()).invoke(expression)

    class_mixer(CloseSub)

    class Pi
      invoke: (expression)->
        _ImplicitMultiplication.build().
          onNumeric(expression).
          append(comps.pi.build())

    class_mixer(Pi)

    class SquareRoot extends ExpressionManipulation
      invoke: (expression)->
        value = @value(expression)
        root = Math.sqrt(parseFloat(value))
        unless isNaN(root)
          num = comps.number.build value: "#{root}"
          comps.expression.buildWithContent [num]
        else
          comps.expression.buildError()
    class_mixer(SquareRoot)


    class _ImplicitMultiplication
      onNumeric: (expression)->
        last = expression.last()
        if last && (last.isNumber() || last instanceof comps.expression || last instanceof comps.pi)
          expression.append(comps.multiplication.build())
        else
          expression

      onNeitherOperatorNorNumber: (expression)->
        last = expression.last()
        if last and !last.isNumber()  and !last.isOperator()
          expression.append(comps.multiplication.build())
        else
          expression

    class_mixer(_ImplicitMultiplication)

    class _OverrideIfOperatorOrAppend
      initialize: (@expression)->
      with: (operator)->
        last = @expression.last()
        if last && last.isOperator()
          @expression.replaceLast(operator)
        else
          @expression.append(operator)
    class_mixer(_OverrideIfOperatorOrAppend)


    class _TrailingOperatorHandling
      initialize: (@expression)->

      getSubexpression: ->
        last = @expression.last()
        last.preceedingSubexpression()

    class_mixer(_TrailingOperatorHandling)

    exports =
      calculate: Calculate
      square: Square
      append_decimal: AppendDecimal
      append_number: AppendNumber
      exponentiate_last: ExponentiateLast
      append_multiplication: AppendMultiplication
      append_addition: AppendAddition
      append_subtraction: AppendSubtraction
      negate_last: Negation
      open_sub_expression: OpenSub
      close_sub_expression: CloseSub
      append_division: AppendDivision
      pi: Pi
      square_root: SquareRoot

    return exports
