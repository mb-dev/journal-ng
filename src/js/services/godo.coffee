 angular.module('app.services')
  .factory 'godoClient', ($q, storageService, $http, $location, userService) ->
    tasks = []
    trips = []
    godoServerUrl = if $location.host().indexOf('local.com') >= 0
      'http://localhost:9000/api/godo'
    else if location.host().indexOf('vagrant.com') >= 0
      'http://api.moshebergman.vagrant.com/api/godo'
    else
      'https://api.moshebergman.com/api/godo'
    authorizationHeaders = {headers: {'Authorization': 'Bearer ' + storageService.getToken() }}

    tasksAPI = {
      fetch: =>
        $http.get(godoServerUrl + '/tasks', authorizationHeaders).then (results) ->
          tasks = results.data
          tasks
      create: (task) ->
        $http.post(godoServerUrl + '/tasks', task, authorizationHeaders).then (results) ->
          tasks.push(results.data)
      update: (task) ->
        $http.put(godoServerUrl + '/tasks/' + task.id, task, authorizationHeaders).then (results) ->
          angular.extend(task, results.data)
          task
    }

    tripsAPI = {
      fetch: =>
        $http.get(godoServerUrl + '/trips', authorizationHeaders).then (results) ->
          trips = results.data
          trips
      create: (trip) ->
        $http.post(godoServerUrl + '/trips', task, authorizationHeaders).then (results) ->
          trips.push(results.data)
      update: (trip) ->
        $http.put(godoServerUrl + '/trips/' + task.id, task, authorizationHeaders).then (results) ->
          angular.extend(trip, results.data)
          trip

    }

    return {
      tasks: tasksAPI
      trips: tripsAPI
    }