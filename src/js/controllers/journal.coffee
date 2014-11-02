angular.module('app.controllers')
  .controller 'JournalIndexController', ($scope, $routeParams, $location, db) ->
    $scope.currentDate = moment()
    if $routeParams.month && $routeParams.year
      $scope.currentDate.year(+$routeParams.year).month(+$routeParams.month - 1)

    db.memories().getByDynamicFilter({date: {month: $scope.currentDate.month(), year: $scope.currentDate.year()}, onlyParents: true}).then (memories) -> 
      db.events().getByDynamicFilter({date: {month: $scope.currentDate.month(), year: $scope.currentDate.year()}}).then (events) -> $scope.$apply ->
        memories = memories.map((item) -> {type: 'memories', modifiedAt: item.modifiedAt, data: item, date: item.date})
        events = events.map((item) -> {type: 'events', modifiedAt: item.modifiedAt, data: item, date: item.date})

        allItems = _.sortBy(memories.concat(events), 'date').reverse()
        $scope.dates = _(allItems).pluck('date').map((date) -> moment(date).format('L')).uniq().valueOf()
        $scope.items = _.groupBy(allItems, (item) -> moment(item.date).format('L'))

    $scope.nextMonth = ->
      $scope.currentDate.add('months', 1)
      $location.path('/journal/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add('months', -1)
      $location.path('/journal/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    

    return