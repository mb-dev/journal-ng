groupItems = (items) ->
  return [] if !items || items.length == 0
  dateGroups = {}
  dates = []
  items.forEach (item) ->
    item.dates.forEach (date) ->
      if dateGroups[date]?
        dateGroups[date].push(item)
      else
        dateGroups[date] = [item]
        dates.push(date)
  finalResult = []
  dates.sort().forEach (date) ->
    finalResult.push({type: 'header', date: date})
    dateGroups[date].sort (a, b) ->
      c1 = if a.completed then 1 else 0
      c2 = if b.completed then 1 else 0
      c1 - c2 || a.id.localeCompare(b.id)
    .forEach (item) ->
      finalResult.push({type: 'item', value: item })
  finalResult

angular.module('app.controllers')
  .controller 'ToDoIndexController', ($scope, $routeParams, $location, godoClient, $modal) ->
    $scope.currentDate = moment()
    if $routeParams.month && $routeParams.year
      $scope.currentDate.year(+$routeParams.year).month(+$routeParams.month - 1)

    godoClient.tasks.fetch().then (result) ->
      $scope.items = result

    $scope.$watch 'items', ->
      $scope.groupedItems = groupItems($scope.items)
    , true

    $scope.newTask = {title: ''}
    $scope.onAddTask = ->
      godoClient.tasks.create($scope.newTask).then ->
        $scope.newTask.title = ''

    $scope.editItem = (item) ->
      editModal = $modal({template: '/partials/todo/editModal.html', show: true});
      editModal.$scope.item = angular.copy(item)
      editModal.$scope.title = 'Edit Task'
      editModal.$scope.saveChanges = ->
        godoClient.tasks.update(editModal.$scope.item).then (savedItem) ->
          angular.extend(item, savedItem)
          editModal.hide()


    $scope.onChangeComplete = (item) ->
      item.completed = !item.completed
      godoClient.tasks.update(item).then (savedItem) ->
        angular.extend(item, savedItem)


    $scope.nextMonth = ->
      $scope.currentDate.add('months', 1)
      $location.path('/todo/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())
    $scope.prevMonth = ->
      $scope.currentDate.add('months', -1)
      $location.path('/todo/' + $scope.currentDate.year().toString() + '/' + ($scope.currentDate.month()+1).toString())

    return