angular.module('app.directives').directive 'dateIntFormatter', ($filter) ->
    angularDateFilter = $filter('date')
    {  
      restrict: 'A',
      require: 'ngModel'
      link: (scope, element, attr, ngModelCtrl) ->
        ngModelCtrl.$formatters.unshift (value) ->
          return '' if !value
          angularDateFilter(moment(value, 'YYYYMMDD').toDate(), 'MM/dd/yyyy')
        ngModelCtrl.$parsers.push (value) ->
          if value then parseInt(moment(value).format('YYYYMMDD'), 10) else null
    }