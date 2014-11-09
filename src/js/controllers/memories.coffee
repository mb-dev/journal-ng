angular.module('app.controllers')
  .controller 'MemoriesIndexController', ($scope, $routeParams, $location, db) ->
    $scope.currentDate = moment()
    if $routeParams.month && $routeParams.year
      $scope.currentDate.year(+$routeParams.year).month(+$routeParams.month - 1)

    db.memories().getItemsByMonthYear($scope.currentDate.month(), $scope.currentDate.year()).then (memories) -> $scope.$apply ->
      $scope.items = memories
    $scope.nextMonth = ->
      $scope.currentDate.add(1, 'months')
      $location.path('/memories/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add(-1, 'months')
      $location.path('/memories/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())

    return

  .controller 'MemoriesFormController', ($scope, $routeParams, $location, journaldb, errorReporter) ->
    db = journaldb
    db.categories().getAllKeys().then (categories) -> $scope.$apply ->
      $scope.allCategories = db.preloaded.categories
    
    db.people().getAll().then (people) -> $scope.$apply ->
      $scope.allPeople = people
    
    updateFunc = null
    if $location.$$url.indexOf('new') > 0
      $scope.type = 'new'
      $scope.title = 'New memory'
      $scope.item = {date: moment().valueOf()}
      updateFunc = db.memories().insert
      $scope.item.people = [parseInt($routeParams.personId, 10)] if $routeParams.personId
      $scope.item.date = parseInt($routeParams.date, 10) if $routeParams.date
    else
      $scope.type = 'edit'
      $scope.title = 'Edit memory'
      $scope.item = db.preloaded.item
      updateFunc = db.memories().updateById

    if $routeParams.eventId
      $scope.event = db.preloaded.event
      $scope.item.events ||= []
      $scope.item.events.push($scope.event.id) if $scope.item.events.indexOf($scope.event.id) < 0
      $scope.item.date = $scope.event.date if $scope.type == 'new'

    if $routeParams.category
      $scope.item.categories ||= []
      $scope.item.categories.push($routeParams.category) if $scope.item.categories.indexOf($routeParams.category) < 0

    if $routeParams.parentMemoryId
      $scope.parentMemory = db.preloaded.parentMemory
      $scope.item.parentMemoryId = $scope.parentMemory.id

    onSuccess = -> $scope.$apply ->
      memoryDate = moment($scope.item.date)
      $location.path($routeParams.returnto || '/journal/' + memoryDate.format('YYYY/MM'))

    $scope.onSubmit = ->
      db.categories().findOrCreate($scope.item.categories)
      .then -> updateFunc($scope.item)
      .then -> db.saveTables([db.tables.memories, db.tables.categories]).then(onSuccess, errorReporter.errorCallbackToScope($scope))

  .controller 'MemoriesShowController', ($scope, $routeParams, db, $location) ->
    $scope.item = db.preloaded.item
    $scope.people = db.preloaded.people
    $scope.events = db.preloaded.events
    $scope.parentMemory = db.preloaded.parentMemory
    db.memories().getItemsByParentMemoryId($scope.item.id).then (childMemories) -> $scope.$apply ->
      $scope.childMemories = childMemories

    $scope.deleteItem = ->

      # delete child memory
      deleteChildPromises = $scope.childMemories.map (childMemory) ->
        db.memories().deleteById(childMemory.id)

      RSVP.all(deleteChildPromises)
      .then -> db.memories().deleteById($scope.item.id)
      .then -> db.saveTables([db.tables.memories]).then -> $scope.$apply ->
        if $scope.item.events
          $location.path('/events/' + $scope.item.events[0])
        else
          date = moment($scope.item.events[0])
          $location.path('/journal/' + date.year().toString() + '/' + date.month().toString())

  .controller 'MemoriesAddMentionController', ($scope, $routeParams, $location, db) ->
    associateCheck = null
    associate = null
    unassociate = null
    onSuccess = null

    $scope.availableMemories = []
    $scope.associatedMemories = []
    $scope.changedMemories = []

    if $routeParams.eventId
      db.events().findById(parseInt($routeParams.eventId), 10).then (event) -> $scope.$apply ->
        $scope.event = event
        associateCheck = (memory) -> memory.mentionedIn && memory.mentionedIn.indexOf($scope.event.id) >= 0
        associate = (memory) -> 
          memory.mentionedIn ||= []
          memory.mentionedIn.push($scope.event.id)
        unassociate = (memory) -> memory.mentionedIn.splice(memory.mentionedIn.indexOf($scope.event.id), 1)
        onSuccess = -> $scope.$apply -> $location.url("/events/#{$scope.event.id}")
    else if $routeParams.personId
      db.people().findById(parseInt($routeParams.personId, 10)).then (person) -> $scope.$apply ->
        $scope.person = person
        associateCheck = (memory) -> memory.mentionedTo && memory.mentionedTo.indexOf($scope.person.id) >= 0
        associate = (memory) -> 
          memory.mentionedTo ||= [] 
          memory.mentionedTo.push($scope.person.id)
        unassociate = (memory) -> memory.mentionedTo.splice(memory.mentionedTo.indexOf($scope.person.id), 1)
        onSuccess = -> $scope.$apply -> $location.url("/people/#{$scope.person.id}")

    db.memories().getAll().then (memories) -> $scope.$apply ->
      memoriesGrouped = _(memories).reverse().groupBy((memory) -> if associateCheck(memory) then 'associated' else 'unassociated').valueOf()

      $scope.availableMemories = memoriesGrouped['unassociated'] || []
      $scope.associatedMemories = memoriesGrouped['associated'] || []

    $scope.associateMemory = (memoryId, memory, index) ->
      associate(memory)
      if $scope.changedMemories.indexOf(memory) < 0
        $scope.changedMemories.push(memory)
      $scope.availableMemories.splice(index, 1)
      $scope.associatedMemories.unshift(memory)

    $scope.unAssociateMemory = (memoryId, memory, index) ->
      unassociate(memory)
      if $scope.changedMemories.indexOf(memory) < 0
        $scope.changedMemories.push(memory)
      $scope.associatedMemories.splice(index, 1)
      $scope.availableMemories.unshift(memory)

    $scope.saveChanges = ->
      async.each $scope.changedMemories, (memory, callback) ->
        db.memories().updateById(memory).then(callback)
      , (err) ->
        if err
          console.log ("failed #{err}")
        else
          db.saveTables([db.tables.memories]).then(onSuccess)