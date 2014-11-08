angular.module('app.controllers')
  .controller 'MiscController', ($scope, $routeParams, $location, db, $injector) ->
    $scope.forceLoadAll = ->
      db.getTables(Object.keys(db.tables), true)

    $scope.forceSaveAll = ->
      db.saveTables(Object.keys(db.tables), true)
