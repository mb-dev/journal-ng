angular.module('app.controllers')
  .controller 'JournalIndexController', ($scope, $routeParams, $location, $timeout, db, $modal) ->
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
      $scope.currentDate.add(1, 'months')
      $location.path('/journal/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add(-1, 'months')
      $location.path('/journal/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    
    $scope.newMemoryUsingModal = ->      
      db.preloaded.item = null
      dialog = $modal({template: '/partials/memories/formDialog.html', show: true});

    $scope.showItemUsingModal = (type, item) ->
      db.preloaded.item = item
      if type == 'events'
        dialog = $modal({template: '/partials/events/showDialog.html', show: true});
      dialog.$scope.$on 'editItem', (event) ->
        dialog.$scope.$destroy()
        $timeout -> 
          $scope.editItemUsingModal(type, item)

    $scope.editItemUsingModal = (type, item) ->
      db.preloaded.item = angular.copy(item)
      if type == 'memories'
        dialog = $modal({template: '/partials/memories/formDialog.html', show: true});
        dialog.$scope.$on 'itemEdited', (event, newItem) ->
          angular.extend(item, newItem)
      else if type == 'events'
        dialog = $modal({template: '/partials/events/formDialog.html', show: true});
        dialog.$scope.$on 'itemEdited', (event, newItem) ->
          angular.extend(item, newItem)


    return