options = {}

defaults =
  debugOptions: false
  suppressErrors: false
  formSelector: 'form[validate]:not([validate="false"])'
  inputSelector: 'input[type="text"], input[type="email"], input[type="number"], input[type="radio"], input[type="checkbox"], textarea, select'
  inputFilter: ':not([validate="false"])'
  validationURLPrefix: '/ajax/validation'
  validClass: 'valid'
  invalidClass: 'error'

builtIns =
  urlComponentRegex: /[^\w\d\._-]/g
  getURLNamespace: ($input) ->
    $form = $input.parents('form')
    namespace = $form.attr('data-validajax-namespace') || $form.attr('name') || $form.attr('id')
    namespace.replace(this.urlComponentRegex, '')
  getURLEndpoint: ($input) ->
    $input.attr('name').replace(this.urlComponentRegex, '')
  removeValidationResidue: ($input) ->
    $input
      .removeData 'validajax-validation-in-progress'
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
    $input.data 'validajax-validation-applied', true
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

  validate = ($input, event) ->
    $input = getAllInputElements $input
    if $input.data 'validajax-validation-in-progress'
      # Validate only on one instance of any given checkbox or radio
      return
    else if $input.data('validajax-validation-applied') and event.type == 'blur'
      # Prevent validation on blur of an input already validated on change
      return
    $input
      .data 'validajax-validation-in-progress', true
      .data 'validajax-validation-applied', false
      .trigger 'beforeInputValidation.validajax'
    $.ajax
      url: [options.validationURLPrefix, options.getURLNamespace($input), options.getURLEndpoint($input)].join '/'
      method: 'get'
      data:
        val: getInputValue($input)
      success: (resp) ->
        showResult($input, resp)
        $input.trigger 'afterInputValidation.validajax', [resp]
      error: (xhr) ->
        if options.suppressErrors
          return
        serverResponse = JSON.parse(xhr.responseText).message
        if (window.console)
          window.console.error "ValidAJAX configuration error:", serverResponse
        else
          window.alert "ValidAJAX configuration error:\n" + serverResponse


  validateOnSubmit = ($form, event) ->
    event.preventDefault()
    $form.trigger 'beforeSubmitValidation.validajax'
    $.when.apply($, selectFields($form, ':not(.' + options.validClass + ')').map -> validate $(this))
      .then ->
        $errors = selectFields $form, '.' + options.invalidClass
        $form.trigger 'afterSubmitValidation.validajax', [$errors.length == 0]
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
        $form.trigger 'beforeFormInitialization.validajax'
        selectFields($form).each ->
          $this = $(this)
          $this.on 'blur change', validate.bind(null, $this)
        $form.on 'submit', validateOnSubmit.bind(null, $form)
        $form.trigger 'afterFormInitialization.validajax'

    if options.debugOptions
      window.ValidAJAX.options = options
)(jQuery)
