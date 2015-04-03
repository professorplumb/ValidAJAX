// Generated by CoffeeScript 1.9.1
(function() {
  var builtIns, defaults, options;

  options = {};

  defaults = {
    debugOptions: false,
    formSelector: 'form[validate]:not([validate="false"])',
    inputSelector: 'input[type="text"], input[type="radio"], input[type="checkbox"], textarea, select',
    inputFilter: ':not([validate="false"])',
    validationURLPrefix: '/ajax/validation',
    validClass: 'valid',
    invalidClass: 'error'
  };

  builtIns = {
    urlComponentRegex: /[^\w\d\._-]/g,
    getURLNamespace: function($input) {
      var $form, namespace;
      $form = $input.parents('form');
      namespace = $form.attr('data-validajax-namespace') || $form.attr('name') || $form.attr('id');
      return namespace.replace(this.urlComponentRegex, '');
    },
    getURLEndpoint: function($input) {
      return $input.attr('name').replace(this.urlComponentRegex, '');
    },
    removeValidationResidue: function($input) {
      return $input.removeData('validajax-validation-in-progress').removeClass([options.validClass, options.invalidClass].join(' ')).siblings('.validajax').remove();
    },
    onValidationSuccess: function($input, resp) {
      return $input.last().addClass(options.validClass).after(resp.message ? $('<span class="validajax">' + resp.message + '</span>') : '');
    },
    onValidationFailure: function($input, resp) {
      return $input.last().addClass(options.invalidClass).after($('<span class="validajax">' + resp.message + '</span>'));
    }
  };

  window.ValidAJAX = (function($) {
    var getAllInputElements, getInputValue, selectFields, showResult, validate, validateOnSubmit;
    selectFields = function($form, refinement) {
      var sel;
      if (refinement == null) {
        refinement = '';
      }
      return $form.find(((function() {
        var i, len, ref, results;
        ref = options.inputSelector.split(', ');
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          sel = ref[i];
          results.push(sel + options.inputFilter + refinement);
        }
        return results;
      })()).join(', '));
    };
    showResult = function($input, resp) {
      options.removeValidationResidue($input);
      $input.data('validajax-validation-applied', true);
      if (resp.success) {
        return options.onValidationSuccess($input, resp);
      } else {
        return options.onValidationFailure($input, resp);
      }
    };
    getAllInputElements = function($indivInput) {
      var $form;
      if ($indivInput.is(':radio, :checkbox')) {
        $form = $indivInput.parents('form');
        return $form.find('[name="' + $indivInput.attr('name') + '"]');
      }
      return $indivInput;
    };
    getInputValue = function($input) {
      var cbox, vals;
      if ($input.is(':radio')) {
        return $input.filter(':checked').val();
      } else if ($input.is(':checkbox')) {
        vals = (function() {
          var i, len, ref, results;
          ref = $input.filter(':checked');
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            cbox = ref[i];
            results.push($(cbox).val());
          }
          return results;
        })();
        return vals.join(',');
      }
      return $input.val();
    };
    validate = function($input, event) {
      $input = getAllInputElements($input);
      if ($input.data('validajax-validation-in-progress')) {
        return;
      } else if ($input.data('validajax-validation-applied') && event.type === 'blur') {
        return;
      }
      $input.data('validajax-validation-in-progress', true).data('validajax-validation-applied', false).trigger('beforeInputValidation.validajax');
      return $.ajax({
        url: [options.validationURLPrefix, options.getURLNamespace($input), options.getURLEndpoint($input)].join('/'),
        method: 'get',
        data: {
          val: getInputValue($input)
        },
        success: function(resp) {
          showResult($input, resp);
          return $input.trigger('afterInputValidation.validajax', [resp]);
        }
      });
    };
    validateOnSubmit = function($form, event) {
      event.preventDefault();
      $form.trigger('beforeSubmitValidation.validajax');
      return $.when.apply($, selectFields($form, ':not(.' + options.validClass + ')').map(function() {
        return validate($(this));
      })).then(function() {
        var $errors;
        $errors = selectFields($form, '.' + options.invalidClass);
        $form.trigger('afterSubmitValidation.validajax', [$errors.length === 0]);
        if ($errors.length > 0) {
          return $errors.first().focus();
        } else {
          return $form[0].submit();
        }
      });
    };
    return {
      init: function(optionsOverrides) {
        var fn, form, forms, i, len;
        options = $.extend({}, defaults, builtIns, optionsOverrides);
        forms = $(options.formSelector);
        fn = function(form) {
          var $form;
          $form = $(form);
          $form.trigger('beforeFormInitialization.validajax');
          selectFields($form).each(function() {
            var $this;
            $this = $(this);
            return $this.on('blur change', validate.bind(null, $this));
          });
          $form.on('submit', validateOnSubmit.bind(null, $form));
          return $form.trigger('afterFormInitialization.validajax');
        };
        for (i = 0, len = forms.length; i < len; i++) {
          form = forms[i];
          fn(form);
        }
        if (options.debugOptions) {
          return window.ValidAJAX.options = options;
        }
      }
    };
  })(jQuery);

}).call(this);

//# sourceMappingURL=validajax.js.map
