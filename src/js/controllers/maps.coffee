angular.module('app.controllers')
  .controller 'MapsIndexController', ($scope, $routeParams, $location, godoClient, $modal) ->
    directionsService = directionsDisplay = autocomplete = map = marker = null

    $scope.tripStart = moment(new Date(2014, 12-1, 19))

    $scope.days = [
      {number: 1, centerLocation: {name: 'Phuket', lat: 7.953951, lng: 98.346883}, points: [
        {"lat":7.892256,"lng":98.295702,"name":"Patong Beach"},
        {"lat":7.8063168,"lng":98.29900709999993,"name":"Kata Noi Beach"}]
      },
      {"number":2,"centerLocation":{"lat":18.7060641,"lng":98.98171630000002,"name":"Chiang Mai"},"points":[
        {"lat":18.782411,"lng":98.98184200000003,"name":"Green Tulip House"},
        {"lat":18.8163889,"lng":98.89194440000006,"name":"Doi Suthep"},
        {"lat":18.792773,"lng":98.99333899999999,"name":"Ginger & Kafe at The house"},
        {"lat":18.79841,"lng":98.96876500000008,"name":"Librarista"}
      ]}
    ]
    $scope.currentDay = $scope.days[0]
    $scope.validPlace = false

    $scope.initializeMaps = -> $scope.$apply ->
      mapOptions = {
        center: $scope.currentDay.centerLocation,
        zoom: 8
      };
     
      map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions); 

      directionsDisplay = new google.maps.DirectionsRenderer();
      directionsService = new google.maps.DirectionsService();
      directionsDisplay.setMap(map);

      refreshDirections()

      autocomplete = new google.maps.places.Autocomplete(document.getElementById('autocomplete'))
      autocomplete.setBounds(map.getBounds())
      google.maps.event.addListener(autocomplete, 'place_changed', onPlaceChanged);

      marker = new google.maps.Marker
        draggable: true

    refreshCenterMaps = ->
      map.setCenter($scope.currentDay.centerLocation)
      autocomplete.setBounds(map.getBounds())

    refreshDirections = ->
      if $scope.currentDay.points.length == 0
        directionsDisplay.set('directions', null)
        marker.setMap(null)
        return
      if $scope.currentDay.points.length == 1
        position = $scope.currentDay.points[0]
        marker.setPosition(new google.maps.LatLng(position.lat, position.lng))
        marker.setMap(map)
        directionsDisplay.set('directions', null)
        return
      length = $scope.currentDay.points.length
      start = $scope.currentDay.points[0]
      end = $scope.currentDay.points[length-1]
      request = {
        origin: new google.maps.LatLng(start.lat, start.lng)
        destination: new google.maps.LatLng(end.lat, end.lng)
        travelMode: google.maps.DirectionsTravelMode.DRIVING
      };
      if length > 2
        request.waypoints = []
        for waypoint in $scope.currentDay.points[1..-2]
          request.waypoints.push(location: new google.maps.LatLng(waypoint.lat, waypoint.lng))
      directionsService.route request, (response, status) ->
        if (status == google.maps.DirectionsStatus.OK)
          directionsDisplay.setDirections(response)

    onPlaceChanged = -> $scope.$apply ->
      place = autocomplete.getPlace();
      $scope.validPlace = place?

    $scope.setOnDay = ->
      place = autocomplete.getPlace();
      $scope.currentDay.centerLocation = place.geometry.location
      $scope.currentDay.centerLocation.name = place.name
      refreshCenterMap()

    $scope.addToDay = ->
      place = autocomplete.getPlace();
      point = {lat: place.geometry.location.k, lng: place.geometry.location.D, name: place.name}
      $scope.currentDay.points.push(point)
      refreshDirections()

    $scope.addDay = ->
      place = autocomplete.getPlace();
      $scope.days.push({number: $scope.days.length+1, centerLocation: {lat: place.geometry.location.k, lng: place.geometry.location.D, name: place.name}, points: []})

    $scope.selectDay = (day) ->
      $scope.currentDay = day
      refreshCenterMaps()
      refreshDirections()

    $scope.movePoint = (day, point, direction) ->
      previousIndex = day.points.indexOf(point)
      day.points.splice(previousIndex, 1)
      day.points.splice(previousIndex + direction, 0, point)
      if day == $scope.currentDay
        refreshDirections()

    $scope.movePointDay = (day, point, direction) ->
      day.points.splice(day.points.indexOf(point), 1)
      newDayIndex = $scope.days.indexOf(day) + direction
      newDay = $scope.days[newDayIndex]
      newDay.points.push(point)
      if day == $scope.currentDay or newDay == $scope.currentDay
        refreshDirections()

    $scope.deletePoint = (day, point) ->
      previousIndex = day.points.indexOf(point)
      day.points.splice(previousIndex, 1)
      if day == $scope.currentDay
        refreshDirections()

    $scope.moveDay = (day, direction) ->
      previousIndex = $scope.days.indexOf(day)
      $scope.days.splice(previousIndex, 1)
      $scope.days.splice(previousIndex + direction, 0, day)
      day.number = index + 1 for day, index in $scope.days

    $scope.deleteDay = (day) -> $scope.$apply ->
      currentIndex = $scope.days.indexOf(day)
      $scope.days.splice(currentIndex, 1)
      day.number = index + 1 for day, index in $scope.days
      $scope.currentDay = $scope.days[currentIndex] or $scope.days[currentIndex-1]

    $scope.dateAt = (day) ->
      $scope.tripStart.clone().add(day.number-1, 'days').format('ddd M/D')