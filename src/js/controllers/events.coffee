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

  .controller 'EventsFormController', ($scope, $routeParams, $location, journaldb, errorReporter) ->
    db = journaldb
    db.categories().getAllKeys().then (categories) -> $scope.$apply ->
      $scope.allCategories = categories
    
    peopleMapper = {}
    db.people().getAll().then (people) -> $scope.$apply ->
      peopleMapper = objectSelectizeConverter(people, 'name')  
      $scope.allPeople = peopleMapper.allDisplayAttrs()
      peopleMapper.toDisplayAttr($scope.item, 'participantIds')

    updateFunc = null

    if db.preloaded.item
      $scope.title = 'Edit event'
      $scope.item = db.preloaded.item
      updateFunc = db.events().updateById
    else
      $scope.title = 'New event'
      $scope.item = {date: db.preloaded.activeDate or moment().valueOf(), associatedMemories: []}
      updateFunc = db.events().insert
      $scope.item.participantIds = [parseInt($routeParams.personId, 10)] if $routeParams.personId
      $scope.item.date = parseInt($routeParams.date, 10) if $routeParams.date

    onSuccess = -> 
      if $scope.$hide?
        $scope.$emit('itemEdited', $scope.item)
        $scope.$hide()
      else
        eventDate = moment($scope.item.date)
        $location.url($routeParams.returnto || '/journal/' + eventDate.format('YYYY/MM'))

    $scope.onSubmit = ->
      peopleMapper.toIdCollection($scope.item, 'participantIds')
      db.categories().findOrCreate($scope.item.categories)
      .then -> updateFunc($scope.item)
      .then -> db.saveTables([db.tables.events, db.tables.categories]).then(onSuccess, errorReporter.errorCallbackToScope($scope))

  .controller 'EventsShowController', ($scope, $routeParams, $location, journaldb) ->
    db = journaldb
    $scope.item = db.preloaded.item
    db.people().findByIds($scope.item.participantIds or []).then (people) -> $scope.$apply ->
      $scope.participants = people
    db.memories().getItemsByEventId($scope.item.id).then (associatedMemories) -> $scope.$apply ->
      $scope.associatedMemories = associatedMemories
    db.memories().getMemoriesMentionedAtEventId($scope.item.id).then (mentionedMemories) -> $scope.$apply ->
      $scope.mentionedMemories = mentionedMemories

    $scope.editItem = ->
      if $scope.$hide?
        $scope.$emit('editItem')
      else
        $location.url("/events/#{$scope.item.id}/edit?returnto=#{$scope.currentLocation}")

    $scope.deleteItem = () ->
      db.events().deleteById($scope.item.id)
      .then -> db.saveTables([db.tables.events])
      .then -> $scope.$apply -> 
        $location.path('/events/')