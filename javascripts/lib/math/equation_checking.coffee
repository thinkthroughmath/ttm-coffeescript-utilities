#= require ./base
#= require lib

class EquationChecking
  initialize: (@manip_source, @exp_traversal, @evaluation, @expression_equality_fn,
    @expression_position, @variables)->

  ensureChecked: ->
    unless @is_checked
      @is_checked = true

  isCorrect: ->
    unless @correct_val

      if @hasEqualsSign()

        @replaced = @manip_source.build_substitute_variables(variables: @variables)
          .perform(@expression_position)

        left_value = @leftValue(@replaced)
        right_value = @rightValue(@replaced)
        @correct_val = @expression_equality_fn(left_value.expression(), right_value.expression())
      else
        @correct_val = false
    @correct_val

  leftValue: (exp)->
    left_hand_side = @manip_source.build_get_left_side().perform(exp)
    left_hand_exp = left_hand_side.expression()
    left_hand_side.clone(expression: @evaluation.build(left_hand_exp).resultingExpression())

  rightValue: (exp)->
    right_hand_side = @manip_source.build_get_right_side().perform(exp)
    right_hand_exp = right_hand_side.expression()
    right_hand_side.clone(expression: @evaluation.build(right_hand_exp).resultingExpression())

  hasEqualsSign: ->
    @exp_traversal.build(@expression_position.expression()).hasEquals()

  hasUnknown: ->
    false

  asJSON: ->
    EquationCheckingJSON.build(@).toJSON()

ttm.class_mixer EquationChecking

class EquationCheckingJSON
  initialize: (@equation_checking)->
  toJSON: ->
    obj = {
      equationIsCorrect: @equation_checking.isCorrect()
      hasEqualsSign: @equation_checking.hasEqualsSign()
      hasUnknown: @equation_checking.hasUnknown()
    }
    JSON.stringify(obj)
ttm.class_mixer EquationCheckingJSON

class EquationCheckingBuilder
  initialize: (@manip_source, @exp_traversal, @evaluation, @equality_fn)->
  build: (expression_position, variables)->
    EquationChecking.build(@manip_source, @exp_traversal, @evaluation, @equality_fn, expression_position, variables)

ttm.class_mixer EquationCheckingBuilder

ttm.lib.math.EquationCheckingBuilder = EquationCheckingBuilder
