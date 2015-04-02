options = {}

defaults =
  debugOptions: false
  formSelector: 'form[validate]:not([validate="false"])'
  inputSelector: 'input[type="text"], input[type="radio"], input[type="checkbox"], textarea, select'
  inputFilter: ':not([validate="false"])'
  validationURLPrefix: '/ajax/validation'
  validationInProgressClass: 'validating'
  validClass: 'valid'
  invalidClass: 'error'

builtIns =
  getURLNamespace: ($input) ->
    $form = $input.parents('form')
    namespace = $form.attr('data-validajax-namespace') || $form.attr('name') || $form.attr('id')
    namespace.toLowerCase()
  getURLEndpoint: ($input) ->
    $input.attr('name')
  removeValidationResidue: ($input) ->
    $input
      .removeData 'validajax-validate-applied'
      .removeClass [options.validClass, options.invalidClass].join(' ')
      .siblings('.validajax')
      .remove()
  onValidationSuccess: ($input, resp) ->
    $input
      .last()
      .addClass options.validClass
      .after if resp.message then $('<span class="validajax">' + resp.message + '</span>') else ''
  onValidationFailure: ($input, resp) ->
    $input
      .last()
      .addClass options.invalidClass
      .after $('<span class="validajax">' + resp.message + '</span>')

window.ValidAJAX = (($) ->
  # Private functions
  selectFields = ($form, refinement) ->
    refinement ?= ''
    $form.find (sel + options.inputFilter + refinement for sel in options.inputSelector.split(', ')).join ', '

  showResult = ($input, resp) ->
    options.removeValidationResidue $input
    if resp.success
      options.onValidationSuccess $input, resp
    else
      options.onValidationFailure $input, resp

  getAllInputElements = ($indivInput) ->
    if $indivInput.is ':radio, :checkbox'
      $form = $indivInput.parents 'form'
      return $form.find('[name="' + $indivInput.attr('name') + '"]')

    return $indivInput

  getInputValue = ($input) ->
    if $input.is ':radio'
      return $input.filter(':checked').val()
    else if $input.is ':checkbox'
      vals = ($(cbox).val() for cbox in $input.filter(':checked'))
      return vals.join ','

    return $input.val()

  validate = ($input) ->
    $input = getAllInputElements $input
    if $input.data 'validajax-validate-applied'
      return
    $input.data 'validajax-validate-applied', true
    $.ajax
      url: [options.validationURLPrefix, options.getURLNamespace($input), options.getURLEndpoint($input)].join '/'
      method: 'get'
      data:
        val: getInputValue($input)
      success: (resp) -> showResult($input, resp)

  validateOnSubmit = ($form, event) ->
    event.preventDefault()
    $form.addClass options.validationInProgressClass
    $.when.apply($, selectFields($form, ':not(.' + options.validClass + ')').map -> validate $(this))
      .then ->
        $form.removeClass options.validationInProgressClass
        $errors = selectFields $form, '.' + options.invalidClass
        if $errors.length > 0
          $errors.first().focus()
        else
          $form[0].submit()

  # Module exports
  init: (optionsOverrides) ->
    options = $.extend({}, defaults, builtIns, optionsOverrides)

    forms = $(options.formSelector)
    for form in forms
      do (form) ->
        $form = $(form)
        selectFields($form).each ->
          $this = $(this)
          $this.on 'blur change', validate.bind(null, $this)
        $form.on 'submit', validateOnSubmit.bind(null, $form)
        $form

    if options.debugOptions
      window.ValidAJAX.options = options
)(jQuery)
