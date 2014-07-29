angular.module('app.filters').filter 'dateIntFormat', ->
  (date) ->
    moment(date, 'YYYYMMDD').format('MMM DD')