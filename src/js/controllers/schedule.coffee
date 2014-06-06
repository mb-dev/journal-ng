angular.module('app.controllers')
  .controller 'ScheduleIndexController', ($q, $scope, $routeParams, $location, journaldb, userService) ->
    $scope.setTitle('Schedule')
    $scope.currentDate = moment()

    applyDateChanges = ->
      filter = {}
      filter.date = {month: $scope.currentDate.month(), year: $scope.currentDate.year()}
      journaldb.calendarEvents().getByDynamicFilter(filter).then (items) ->
        $scope.$apply(-> $scope.items = items)

    if $routeParams.month? && $routeParams.year?
      $scope.currentDate.year(+$routeParams.year).month(+$routeParams.month - 1)
      applyDateChanges()
    else
      applyDateChanges()

    $scope.nextMonth = ->
      $scope.currentDate.add('months', 1)
      $location.path('/schedule/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add('months', -1)
      $location.path('/schedule/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())

    convertFromGoogle = (gcalEvent) ->
      if !gcalEvent.start || !gcalEvent.end
        debugger

      eventStartDate = moment(gcalEvent.start.date) if gcalEvent.start.date
      eventStartDate = moment(gcalEvent.start.dateTime) if gcalEvent.start.dateTime
      eventEndDate = moment(gcalEvent.end.date) if gcalEvent.end.date
      eventEndDate = moment(gcalEvent.end.dateTime) if gcalEvent.end.dateTime

      if(!eventStartDate || !eventEndDate) 
        debugger

      {
        gcalId: gcalEvent.id
        title: gcalEvent.summary
        date: eventStartDate.unix()
        duration: eventEndDate.diff(eventStartDate, 'hours')
      }
    $scope.syncSchedule = ->
      userService.getEvents().then (response) ->
        events = response.data.filter((item) -> item.status == 'confirmed').map(convertFromGoogle)
        journaldb.calendarEvents().clearAll().then ->
          journaldb.calendarEvents().insertMultiple(events).then ->
            journaldb.saveTables([journaldb.tables.calEvents]).then ->
              $scope.showSuccess('Calendar sync completed')

.controller 'ScheduleShowController', ($scope, $routeParams, journaldb, $location) ->
  itemId = parseInt($routeParams.itemId, 10)
  journaldb.calendarEvents().findById(itemId).then (item) ->
    $scope.$apply(-> $scope.item = item)

.controller 'ScheduleFormController', ($scope, $routeParams, $location, journaldb, errorReporter) ->
  $scope.title = 'Edit Schedule'
  itemId = parseInt($routeParams.itemId, 10)
  $scope.categories = [
      'Chores', # cleaning the house etc.
      'Friends', # spending time socially
      'Work', # spending time at work
      'Programming', # working on side projects
      'Active::Hiking', 
      'Active::Biking',
      'Active::Running',
      'Jewish Activities',
      'Meta',
      'Ignore'
    ]
  journaldb.calendarEvents().findById(itemId).then (item) ->
    $scope.$apply(-> $scope.item = item)

  $scope.onSubmit = (fetchNextItem) ->
    item = $scope.item
    journaldb.calendarEvents().updateById(item).then ->
      journaldb.saveTables([journaldb.tables.calEvents]).then ->
        journaldb.calendarEvents().getNextItem(item.id).then (nextItem) ->
          $scope.$apply ->
            $location.path('/schedule/' + nextItem.id + '/edit') 


  $scope.onIgnore = (fetchNextItem) ->
    item = $scope.item
    item.ignored = true
    journaldb.calendarEvents().updateById(item).then ->
      journaldb.saveTables([journaldb.tables.calEvents]).then ->
        journaldb.calendarEvents().getNextItem(item.id).then (nextItem) ->
          $scope.$apply ->
            $location.path('/schedule/' + nextItem.id + '/edit') 