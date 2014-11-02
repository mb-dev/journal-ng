angular.module('app.controllers')
  .controller 'PeopleIndexController', ($scope, $routeParams, $location, db) ->
    db.people().getAll().then (people) -> $scope.$apply -> 
      $scope.items = _.groupBy(people, (item) -> item.categories[0])
      $scope.categories = Object.keys($scope.items).sort()

    return

  .controller 'PeopleFormController', ($scope, $routeParams, $location, db, errorReporter) ->
    $scope.allCategories = db.preloaded.categories

    updateFunc = null
    if $location.$$url.indexOf('new') > 0
      $scope.groupNames = ''
      $scope.title = 'New person'
      $scope.item = {}
      updateFunc = db.people().insert
    else
      $scope.title = 'Edit person'
      $scope.item = db.preloaded.item
      updateFunc = db.people().updateById

    onSuccess = -> $scope.$apply -> 
      $location.path($routeParams.returnto || '/people/' + $scope.item.id)

    $scope.onSubmit = ->
      db.categories().findOrCreate($scope.item.categories)
      .then -> db.categories().findOrCreate($scope.item.interests)
      .then -> updateFunc($scope.item)
      .then -> db.saveTables([db.tables.people, db.tables.categories])
      .then(onSuccess, errorReporter.errorCallbackToScope($scope))

  .controller 'PeopleShowController', ($scope, $routeParams, db) ->
    $scope.item = db.preloaded.item

    if $scope.item
      db.events().getEventsByParticipantId($scope.item.id).then (events) -> $scope.$apply ->
        $scope.events = events
      db.memories().getMemoriesByPersonId($scope.item.id).then (memories) -> $scope.$apply ->
        $scope.memories = memories
      db.memories().getMemoriesMentionedToPersonId($scope.item.id).then (memories) -> $scope.$apply ->
        $scope.mentionedMemories = memories