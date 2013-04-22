#= require almond
#= require lib
#= require widgets/ui_elements 
#= require lib/math/buttons

define 'equation_builder', ["lib/class_mixer", "lib/math/buttons", 'widgets/ui_elements'], (class_mixer, math_buttons, ui_elements)->
  class EquationBuilder
    initialize: (@opts)->
      math_button_builder = math_buttons.makeBuilder()
      ui = ui_elements
      @buttons = _EquationBuilderButtons.build(math_button_builder)

      # temporary
      #equation_builder_data = '{"variables":[{"variableName":"time","isUnknown":"false","variableValue":"1.5","unitName":"hours"},{"variableName":"distance","isUnknown":"false","variableValue":"12","unitName":"miles"},{"variableName":"speed","isUnknown":"true","variableValue":"8","unitName":"mph"}]}'
      #eval('equation_builder_data = ' + equation_builder_data)

      if @opts.variables
        @registerVariables()
      @layout = _EquationBuilderLayout.build(ui, @buttons)
      @layout.render(@opts.element)

    registerVariables: (variables)->
      variable_buttons = @buttons.variableButtons(variables)
      @layout.renderVariablePanel(variable_buttons)

  class_mixer(EquationBuilder)

  class _EquationBuilderButtons
    initialize: (@builder)->
      @numbers = @builder.base10Digits(click: (num)=> @numberClick(num))
      @multiplication = @builder.multiplication click: => @multiplicationClick()
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
      
    variableButtons: (variables)->
      @variables = @builder.variables
        variables: variables,
        click: (variable)=> @variableClick(variable)
      
    piClick: ->
    rparenClick: ->
    lparenClick: ->
    exponentClick: ->
    square_rootClick: ->
    squareClick: ->
    clearClick: ->
    equalsClick: ->
    subtractionClick: ->
    divisionClick: ->
    multiplicationClick: ->
    additionClick: ->
    multiplicationClick: ->
    numberClick: (val)->
    variableClick: (variable)->
  class_mixer(_EquationBuilderButtons)

  class _EquationBuilderLayout
    initialize: (@ui, @buttons, @variables)->
    render: (@element)->
      element = @element
      @ui.math_display_builder.build(class: "equation-display").render(element: element)
      @renderNumberPanel()
      @renderControlPanel()
      if @variables
        @renderVariablePanel()
    renderNumberPanel: ->
      number_panel = $("<div class='number-panel'></div>")
      @element.append number_panel
      @render_numbers [7..9], number_panel
      @render_numbers [4..6], number_panel
      @render_numbers [1..3], number_panel
      @render_numbers [0], number_panel
      @buttons.decimal.render(element: number_panel)
      @buttons.equals.render(element: number_panel)

    render_numbers: (nums, element)->
      for num in nums
        @buttons.numbers[num].render(element: element)

    renderControlPanel: ->
      control_panel = $("<div class='control-panel'></div>")
      @element.append control_panel
      
      @buttons.multiplication.render(element: control_panel)
      @buttons.addition.render(element: control_panel)
      @buttons.multiplication.render(element: control_panel)
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





  return EquationBuilder



