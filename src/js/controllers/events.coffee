angular.module('app.controllers')
  .controller 'EventsIndexController', ($scope, $routeParams, $location, db) ->
    applyDateChanges = ->
      db.events().getItemsByMonthYear($scope.currentDate.month(), $scope.currentDate.year()).then (items) -> $scope.$apply ->
        $scope.items = items

    $scope.currentDate = moment()
    if $routeParams.month && $routeParams.year
      $scope.currentDate.year(+$routeParams.year).month(+$routeParams.month - 1)

    applyDateChanges()
    $scope.nextMonth = ->
      $scope.currentDate.add(1, 'months')
      applyDateChanges()
      $location.path('/events/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add(-1, 'months')
      applyDateChanges()
      $location.path('/events/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())

    return

  .controller 'EventsFormController', ($scope, $routeParams, $location, db, errorReporter) ->
    $scope.allCategories = db.preloaded.categories
    $scope.allPeople = db.preloaded.people
    updateFunc = null

    if $location.$$url.indexOf('new') > 0
      $scope.title = 'New event'
      $scope.item = {date: moment().valueOf(), associatedMemories: []}
      updateFunc = db.events().insert
      $scope.item.participantIds = [parseInt($routeParams.personId, 10)] if $routeParams.personId
      $scope.item.date = parseInt($routeParams.date, 10) if $routeParams.date
    else
      $scope.title = 'Edit event'
      $scope.item = db.preloaded.item
      updateFunc = db.events().updateById

    onSuccess = -> $location.path($routeParams.returnto || '/events/' + $scope.item.id)

    $scope.onSubmit = ->
      db.categories().findOrCreate($scope.item.categories)
      .then -> updateFunc($scope.item)
      .then -> db.saveTables([db.tables.events, db.tables.categories]).then(onSuccess, errorReporter.errorCallbackToScope($scope))

  .controller 'EventsShowController', ($scope, $routeParams, db) ->
    $scope.item = db.preloaded.item
    $scope.participants = db.preloaded.participants
    db.memories().getItemsByEventId($scope.item.id).then (associatedMemories) -> $scope.$apply ->
      $scope.associatedMemories = associatedMemories
    db.memories().getMemoriesMentionedAtEventId($scope.item.id).then (mentionedMemories) -> $scope.$apply ->
      $scope.mentionedMemories = mentionedMemories

    $scope.deleteItem = () ->
      db.events().deleteById($scope.item.id)
      .then -> db.saveTables([db.tables.events])
      .then -> $scope.$apply -> 
        $location.path('/events/')