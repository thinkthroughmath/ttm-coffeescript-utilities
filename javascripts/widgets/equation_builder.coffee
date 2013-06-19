#= require almond
#= require lib
#= require lib/logger
#= require lib/math
#= require lib/math/buttons
#= require lib/math/expression_to_mathml_conversion
#= require lib/math/expression_manipulation
#= require lib/math/expression_position
#= require widgets/mathml_display
#= require widgets/equation_builder_rendered_mathml_modifier

ttm.define 'equation_builder',
  ["lib/class_mixer", "lib/math/buttons", 'lib/math', 'lib/historic_value',
   'lib/math/expression_to_mathml_conversion', 'logger',
   'lib/math/expression_manipulation'],
  ( class_mixer, math_buttons, math, historic_value, mathml_converter_builder,
    logger_builder, expression_manipulation_source_builder)->
    class EquationBuilder
      initialize: (@opts)->
        math_button_builder = math_buttons.makeBuilder()

        expression_component_source = ttm.lib.math.ExpressionComponentSource.build()

        expression_position_builder = ttm.lib.math.ExpressionPosition

        @expression_manipulation_source = expression_manipulation_source_builder.build(
          expression_component_source,
          expression_position_builder)

        @expression_position_value = historic_value.build()
        reset = @expression_manipulation_source.build_reset().perform()
        @expression_position_value.update(reset)

        @buttons = _EquationBuilderButtonsLogic.build(
          math_button_builder,
          @expression_manipulation_source)

        @logger = @opts.logger || logger_builder.build()


        equation_component_retriever = EquationComponentRetriever.
          build(@expression_position_value, ttm.lib.math.ExpressionTraversal)
        mathml_display_modifier = ttm.widgets.EquationBuilderRenderedMathMLModifier.
          build(
            equation_component_retriever
            (id, type)=> @expressionPositionSelected(id, type)
            => @expression_position_value.current()
            @opts.element)

        display = ttm.widgets.MathMLDisplay.build
          mathml_renderer: @opts.mathml_renderer
          after_update: ->
            mathml_display_modifier.afterUpdate.apply(mathml_display_modifier, arguments)

        @layout = _EquationBuilderLayout.build(
          display,
          @buttons)

        @layout.render(@opts.element)

        if @opts.variables
          @registerVariables(@opts.variables)

        @mathml_converter = mathml_converter_builder.build(@expression_component_source)

        @logic = _EquationBuilderLogic.build(
          (opts)=> @expression_component_source.build_expression(opts),
          @expression_position_value,
          display,
          @mathml_converter,
          @logger)

        @buttons.setLogic @logic
        @logic.updateDisplay()

      registerVariables: (@variables)->
        variable_buttons = @buttons.variableButtons(@variables)
        @layout.renderVariablePanel(variable_buttons)

      # leaving in until know is not necessary for tests
      mathML: ->
        @logic.mathML()

      expressionPositionSelected: (id, type)->
        cmd = @expression_manipulation_source.build_update_position(element_id: id, type: type)
        @logic.command(cmd)

    class_mixer(EquationBuilder)

    class _EquationBuilderLogic
      initialize: (@build_expression, @expression_position, @display, @mathml_converter, @logger)->
        @updateDisplay()

      command: (cmd)->
        results = cmd.perform(@expression_position.current())
        @expression_position.update(results)
        @updateDisplay()

      updateDisplay: ->
        mathml = @mathML()
        @display.update(mathml)

      mathML: ->
        @mathml_converter.convert(@expression_position.current())

    class_mixer(_EquationBuilderLogic)

    class _EquationBuilderButtonsLogic
      initialize: (@builder, @commands)->
        @numbers = @builder.base10Digits(click: (num)=> @numberClick(num))
        @decimal = @builder.decimal click: => @decimalClick()
        @negative = @builder.negative click: => @negativeClick()
        @addition = @builder.addition click: => @additionClick()
        @multiplication = @builder.multiplication click: => @multiplicationClick()
        @division = @builder.division click: => @divisionClick()
        @subtraction = @builder.subtraction click: => @subtractionClick()
        @equals = @builder.equals click: => @equalsClick()
        @clear = @builder.clear click: => @clearClick()
        @square = @builder.square click: => @squareClick()
        @square_root = @builder.square_root click: => @square_rootClick()
        @exponent = @builder.exponent click: => @exponentClick()
        @lparen = @builder.lparen click: => @lparenClick()
        @rparen = @builder.rparen click: => @rparenClick()
        @pi = @builder.pi click: => @piClick()

      setLogic: ((@logic)->)
      variableButtons: (variables)->
        @variables = @builder.variables
          variables: variables,
          click: (variable)=> @variableClick(variable)
      piClick: ->
        @logic.command @commands.build_append_pi()
      rparenClick: ->
        @logic.command @commands.build_close_sub_expression()
      lparenClick: ->
        @logic.command @commands.build_append_open_sub_expression()
      exponentClick: ->
        @logic.command @commands.build_append_exponentiation()
      square_rootClick: ->
        @logic.command @commands.build_append_root(degree: 2)
      squareClick: ->
        @logic.command @commands.build_exponentiate_last(power: 2, power_closed: true)
      decimalClick: ->
        @logic.command @commands.build_append_decimal()
      clearClick: ->
        @logic.command @commands.build_reset()
      equalsClick: ->
        @logic.command @commands.build_append_equals()
      subtractionClick: ->
        @logic.command @commands.build_append_subtraction()
      divisionClick: ->
        @logic.command @commands.build_append_division()
      multiplicationClick: ->
        @logic.command @commands.build_append_multiplication()
      additionClick: ->
        @logic.command @commands.build_append_addition()
      numberClick: (val)->
        @logic.command @commands.build_append_number(value: val.value)
      variableClick: (variable)->
        @logic.command @commands.build_append_variable(variable: variable.value)

    class_mixer(_EquationBuilderButtonsLogic)

    class _EquationBuilderLayout
      initialize: (@display, @buttons)->
      render: (@parent)->
        @element = $("<div class='equation-builder'></div>")
        @parent.append(@element)
        @display.render(class: "equation-display", element: @element)

        @renderNumberPanel()
        @renderControlPanel()

      renderNumberPanel: ->
        number_panel = $("<div class='number-panel'></div>")
        @renderNumbers [7..9], number_panel
        @renderNumbers [4..6], number_panel
        @renderNumbers [1..3], number_panel
        @renderNumbers [0], number_panel
        @buttons.decimal.render(element: number_panel)
        @buttons.equals.render(element: number_panel)

        @element.append number_panel

      renderNumbers: (nums, element)->
        for num in nums
          @buttons.numbers[num].render(element: element)

      renderControlPanel: ->
        control_panel = $("<div class='control-panel'></div>")
        @element.append control_panel

        @buttons.multiplication.render(element: control_panel)
        @buttons.addition.render(element: control_panel)
        @buttons.division.render(element: control_panel)
        @buttons.subtraction.render(element: control_panel)
        @buttons.negative.render(element: control_panel)
        @buttons.clear.render(element: control_panel)
        @buttons.square.render(element: control_panel)
        @buttons.square_root.render(element: control_panel)
        @buttons.exponent.render(element: control_panel)
        @buttons.lparen.render(element: control_panel)
        @buttons.rparen.render(element: control_panel)
        @buttons.pi.render(element: control_panel)

      renderVariablePanel: (@variable_buttons)->
        variable_panel = $("<div class='variable-panel'></div>")
        for v in @variable_buttons
          v.render(element: variable_panel)
        @element.append(variable_panel)

    class_mixer(_EquationBuilderLayout)

    class EquationComponentRetriever
      initialize: (@exp_pos_val, @traversal_builder)->
      findForID: (id)->
        exp = @exp_pos_val.current().expression()
        @traversal_builder.build(exp).findForID(id)

    class_mixer(EquationComponentRetriever)

    return EquationBuilder


