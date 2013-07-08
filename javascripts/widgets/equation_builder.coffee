#= require almond
#= require lib
#= require lib/math
#= require lib/math/expression_to_mathml_conversion
#= require lib/math/expression_manipulation
#= require lib/math/expression_position
#= require lib/math/equation_checking
#= require widgets/mathml_display
#= require widgets/equation_builder_rendered_mathml_modifier
#= require widgets/math_buttons

ttm.define 'equation_builder',
  ["lib/class_mixer", "lib/math/buttons", 'lib/historic_value',
   'lib/math/expression_to_mathml_conversion'],
  ( class_mixer, math_buttons, historic_value, mathml_converter_builder)->
    class EquationBuilder
      initialize: (opts={})->
        @element = opts.element
        @checkCorrectCallback = opts.check_correct_callback

        # save the equation builder onto the dom element for external messaging
        opts.element[0].equation_builder = @

        math_button_builder = math_buttons.makeBuilder()

        @math_lib = ttm.lib.math.math_lib.build()

        expression_component_source = @math_lib.components
        expression_position_builder = @math_lib.expression_position
        @expression_manipulation_source = @math_lib.commands

        @expression_position_value = historic_value.build()
        reset = @expression_manipulation_source.build_reset().perform()
        @expression_position_value.update(reset)

        @buttons = _EquationBuilderButtonsLogic.build(
          math_button_builder,
          @expression_manipulation_source)

        equation_component_retriever = EquationComponentRetriever.
          build(@expression_position_value, @math_lib.traversal)

        mathml_display_modifier = ttm.widgets.EquationBuilderRenderedMathMLModifier.
          build(
            equation_component_retriever
            (id, type)=> @expressionPositionSelected(id, type)
            => @expression_position_value.current()
            opts.element)

        display = ttm.widgets.MathMLDisplay.build
          mathml_renderer: opts.mathml_renderer
          after_update: ->
            mathml_display_modifier.afterUpdate.apply(mathml_display_modifier, arguments)

        @layout = _EquationBuilderLayout.build(
          display,
          @buttons)

        @layout.render(opts.element)

        if opts.variables
          @registerVariables(opts.variables)

        @mathml_converter = mathml_converter_builder.build(@expression_component_source)

        @logic = _EquationBuilderLogic.build(
          (opts)=> @expression_component_source.build_expression(opts),
          @expression_position_value,
          display,
          @mathml_converter,
          )

        @buttons.setLogic @logic
        @logic.updateDisplay()

      registerVariables: (@variables)->
        variable_buttons = @buttons.variableButtons(@variables)
        @layout.renderVariablesInPanel(variable_buttons)
        @layout.renderExplanatoryTableEntries(@variables)

      # leaving in until know is not necessary for tests
      mathML: ->
        @logic.mathML()

      expressionPositionSelected: (id, type)->
        cmd = @expression_manipulation_source.build_update_position(element_id: id, type: type)
        @logic.command(cmd)

      checkCorrect: ->
        checked_json = @math_lib.equation_checking.build(
          @expression_position_value.current(),
          @variables).asJSON()
        @checkCorrectCallback(checked_json)

    class_mixer(EquationBuilder)

    class _EquationBuilderLogic
      initialize: (@build_expression, @expression_position, @display, @mathml_converter)->
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
        @negative_slash_positive = @builder.negative_slash_positive click: => @negativeClick()

        @addition = @builder.addition click: => @additionClick()
        @multiplication = @builder.multiplication click: => @multiplicationClick()
        @division = @builder.division click: => @divisionClick()
        @subtraction = @builder.subtraction click: => @subtractionClick()
        @equals = @builder.equals click: => @equalsClick()
        @clear = @builder.clear click: => @clearClick()

        @square = @builder.square click: => @squareClick()
        @cube = @builder.square click: => @squareClick()
        @exponent = @builder.exponent click: => @exponentClick()
        @exponent = @builder.exponent click: => @exponentClick()

        @square_root = @builder.root radicand: "x", click: => @square_rootClick()
        @third_root = @builder.root degree: 3, radicand: "x", click: => @third_rootClick()
        @nth_root = @builder.root degree: "x", radicand: "y", click: => @third_rootClick()

        @lparen = @builder.lparen click: => @lparenClick()
        @rparen = @builder.rparen click: => @rparenClick()
        @pi = @builder.pi click: => @piClick()

        @sin = @builder.fn value: "sin", label: "sin", click: => @sinClick()
        @cos = @builder.fn value: "cos", label: "cos", click: => @cosClick()
        @tan = @builder.fn value: "tan", label: "tan", click: => @tanClick()

        @arcsin = @builder.fn value: "arcsin", label: "arcsin", click: => @arcsinClick()
        @arccos = @builder.fn value: "arccos", label: "arccos", click: => @arccosClick()
        @arctan = @builder.fn value: "arctan", label: "arctan", click: => @arctanClick()

        @numerator_denominator = @builder.numerator_denominator click: => @numerator_denominatorClick()

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
      sinClick: ->
        @logic.command @commands.build_append_sin()
      cosClick: ->
        @logic.command @commands.build_append_cos()
      tanClick: ->
        @logic.command @commands.build_append_tan()
      arcsinClick: ->
        @logic.command @commands.build_append_arcsin()
      arccosClick: ->
        @logic.command @commands.build_append_arccos()
      arctanClick: ->
        @logic.command @commands.build_append_arctan()

    class_mixer(_EquationBuilderButtonsLogic)

    class _EquationBuilderLayout
      initialize: (@display, @buttons)->
      render: (@parent)->
        elt = $("""
          <div class='equation-builder'>
            <div class='equation-builder-main'></div>
          </div>
        """)
        @wrapper = elt
        @element = elt.find("div.equation-builder-main")

        @parent.append(@wrapper)
        @display.render(class: "equation-display", element: @element)

        @renderExplanatoryTable()
        @renderVariablePanel()
        @renderControlPanel()
        @renderDropdown()
        @renderNumberPanel()
        @renderAdvancedPanel()

      renderDropdown: ->
        @extra_buttons = $("""
          <div class='equation-builder-extra-buttons'>
            <div class='numbers'>
              <div class='buttons'>
                <div class='buttons-wrap'>
                </div>
              </div>
              <div class='link-wrap'><a href='#' class='extra-buttons-handle'><span class='icon-caret-down'></span> Numbers</a></div>
            </div>

            <div class='advanced'>
              <div class='buttons'>
                <div class='buttons-wrap'>
                </div>
              </div>
              <div class='link-wrap'><a href='#' class='extra-buttons-handle'><span class='icon-caret-down'></span> Advanced</a></div>
            </div>
          </div>
        """)

        @wrapper.append @extra_buttons

        @extra_buttons.find("a.extra-buttons-handle").on "click", ->
          $(@).find("span").toggleClass 'icon-caret-down'
          $(@).find("span").toggleClass 'icon-caret-up'
          $(@).parent().parent().find(".buttons").slideToggle(400)
          false

      renderNumberPanel: ->
        number_panel = $("<div class='number-panel'></div>")
        @renderNumbers [7..9], number_panel
        @renderNumbers [4..6], number_panel
        @renderNumbers [1..3], number_panel
        @renderNumbers [0], number_panel
        @buttons.decimal.render(element: number_panel)

        @extra_buttons.find(".numbers .buttons  .buttons-wrap").append number_panel


      renderAdvancedPanel: ->
        advanced_panel = $("<div class='advanced-panel'></div>")
        @buttons.sin.render(element: advanced_panel)
        @buttons.cos.render(element: advanced_panel)
        @buttons.tan.render(element: advanced_panel)
        @buttons.arcsin.render(element: advanced_panel)
        @buttons.arccos.render(element: advanced_panel)
        @buttons.arctan.render(element: advanced_panel)
        @extra_buttons.find(".advanced .buttons  .buttons-wrap").append advanced_panel


      renderNumbers: (nums, element)->
        for num in nums
          @buttons.numbers[num].render(element: element)

      renderExplanatoryTable: ->
        @explanatory_table = $("""
          <div class='explanatory-table'>
            <p>Use this table as a guide</p>
            <table>
              <thead>
                <tr>
                  <th class='number'>Number</th>
                  <th class='unit'>Unit</th>
                  <th class='variable-description'>Description</th>
                </tr>
              </thead>
              <tbody>
              </tbody>
            </table>
          </div>
        """)
        @element.append(@explanatory_table)



      explanatoryTableRow = (variable)->
        value = if variable.is_unknown then "?" else variable.value
        $("""
          <tr>
            <td>#{value}</td>
            <td>#{variable.unit}</td>
            <td>#{variable.name}</td>
          </tr>
        """)

      renderExplanatoryTableEntries: (@variables)->
        tbody = @explanatory_table.find("tbody")
        for v in @variables
          tbody.append(explanatoryTableRow(v))

      renderControlPanel: ->
        control_panel = $("""
          <div class='control-panel'>
            <p>Use these to show the relationship between values.</p>
            <div class='controls-wrap'>
            </div>
          </div>
        """)
        @element.append control_panel
        control_panel = control_panel.find('.controls-wrap')

        @buttons.subtraction.render(element: control_panel)
        @buttons.addition.render(element: control_panel)
        @buttons.multiplication.render(element: control_panel)

        @buttons.division.render(element: control_panel)
        @buttons.negative_slash_positive.render(element: control_panel)
        @buttons.numerator_denominator.render(element: control_panel)

        @buttons.square.render(element: control_panel)
        @buttons.cube.render(element: control_panel)
        @buttons.exponent.render(element: control_panel)

        @buttons.square_root.render(element: control_panel)
        @buttons.third_root.render(element: control_panel)
        @buttons.nth_root.render(element: control_panel)

        @buttons.pi.render(element: control_panel)
        @buttons.lparen.render(element: control_panel)
        @buttons.rparen.render(element: control_panel)

        @buttons.clear.render(element: control_panel)
        @buttons.equals.render(element: control_panel)

      renderVariablePanel: ->
        @variable_panel = $("""
          <div class='variable-panel'>
            <p>Use these as values for the equation</p>
          </div>""")
        @element.append(@variable_panel)

      renderVariablesInPanel: (@variable_buttons)->
        for v in @variable_buttons
          v.render(element: @variable_panel)

    class_mixer(_EquationBuilderLayout)

    class EquationComponentRetriever
      initialize: (@exp_pos_val, @traversal_builder)->
      findForID: (id)->
        exp = @exp_pos_val.current().expression()
        @traversal_builder.build(exp).findForID(id)

    class_mixer(EquationComponentRetriever)


    window.ttm.EquationBuilder = EquationBuilder
    return EquationBuilder


