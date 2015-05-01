angular.module('app.controllers')
  .controller 'MapsIndexController', ($scope, $routeParams, $location, $modal) ->
    $scope.tripStart = moment(new Date(2014, 12-1, 19))

    storageService = (->

      initializeStorage: ->
        ref = new Firebase("boiling-torch-8739.firebaseio.com/trips")


        ref.authWithOAuthPopup "google", (error, authData) ->
          if error
            console.log("Authentication failed:", error);
          else
            console.log("Logged in as:", authData.uid)

        ref.on 'value', (snapshot) ->
          $scope.days = snapshot.val()
          if !$scope.days or $scope.days.length == 0
            $scope.days = defaultDays
            ref.set(defaultDays)
    )()

    googleMapsService = (->
      firebaseRef = directionsService = directionsDisplay = autocomplete = map = marker = null

      events = {
        onPlaceChanged: ->
          console.log 'place changed'
      }

      initializeMaps: ->
        mapOptions = {
          #center: $scope.currentDay.centerLocation,
          zoom: 8
        };

        map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

        directionsDisplay = new google.maps.DirectionsRenderer();
        directionsService = new google.maps.DirectionsService();
        directionsDisplay.setMap(map);

        refreshDirections()

        autocomplete = new google.maps.places.Autocomplete(document.getElementById('autocomplete'))
        autocomplete.setBounds(map.getBounds())
        google.maps.event.addListener(autocomplete, 'place_changed', events.onPlaceChanged);

        marker = new google.maps.Marker
          draggable: true

      # auto complete

      isPlaceSelected: ->
        place = autocomplete.getPlace()
        place?

      getPointFromAutoComplete: ->
        place = autocomplete.getPlace()
        lat: place.geometry.location.lat(), lng: place.geometry.location.lng()

      getNameFromAutoComplete: ->
        place = autocomplete.getPlace()
        place.name

      # map
      displayPointOnMap: (point) ->
        marker.setPosition(new google.maps.LatLng(point.lat, point.lng))
        marker.setMap(map)

      panToPoint: ->
        map.panTo(marker.getPosition())

      clearPoint: ->
        marker.setMap(null)

      refreshCenterMap: (centerPoint) ->
        map.setCenter(centerPoint)
        setTimeout ->
          autocomplete.setBounds(map.getBounds())
        , 0

      # directions
      clearDirections: ->
        directionsDisplay.set('directions', null)

      displayDirections: (points) ->
        length = points.length
        start = points[0]
        end = points[length-1]
        request = {
          origin: new google.maps.LatLng(start.lat, start.lng)
          destination: new google.maps.LatLng(end.lat, end.lng)
          travelMode: google.maps.DirectionsTravelMode.DRIVING
        };
        if length > 2
          request.waypoints = []
          for waypoint in points[1..-2]
            request.waypoints.push(location: new google.maps.LatLng(waypoint.lat, waypoint.lng))
        directionsService.route request, (response, status) ->
          if (status == google.maps.DirectionsStatus.OK)
            directionsDisplay.setDirections(response)

      events: events
    )()

    defaultDays = [
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

    $scope.days = []

    $scope.currentDay = $scope.days[0]
    $scope.validPlace = false

    if google?
      googleMapsService.initializeMaps()
      storageService.initializeStorage()

    refreshCenterMap = ->
      googleMapsService.refreshCenterMap($scope.currentDay.centerLocation)

    refreshDirections = ->
      return unless $scope.currentDay
      if $scope.currentDay.points.length == 0
        googleMapsService.clearDirections()
        googleMapsService.clearPoint()
        return
      if $scope.currentDay.points.length == 1
        point = $scope.currentDay.points[0]
        googleMapsService.displayPointOnMap(point)
        googleMapsService.clearDirections()
        return
      googleMapsService.displayDirections($scope.currentDay.points)

    googleMapsService.events.onPlaceChanged = ->
      $scope.$apply ->
        $scope.validPlace = googleMapsService.isPlaceSelected()
        $scope.search()

    $scope.initializeMaps = -> $scope.$apply ->
      if google?
        googleMapsService.initializeMaps()

    $scope.initializeStorage = -> $scope.$apply ->
      storageService.initializeStorage()

    $scope.setOnDay = ->
      place = autocomplete.getPlace()
      $scope.currentDay.centerLocation = place.geometry.location
      $scope.currentDay.centerLocation.name = place.name
      refreshCenterMap()

    $scope.search = ->
      point = googleMapsService.getPointFromAutoComplete()
      return unless point.lat and point.lng
      googleMapsService.displayPointOnMap(point)
      setTimeout ->
        googleMapsService.panToPoint()
      , 100

    $scope.addToDay = ->
      point = googleMapsService.getPointFromAutoComplete()
      point.name = googleMapsService.getNameFromAutoComplete()
      $scope.currentDay.points.push(point)
      refreshDirections()

    $scope.addDay = ->
      point = googleMapsService.getPointFromAutoComplete()
      point.name = googleMapsService.getNameFromAutoComplete()
      $scope.days.push({number: $scope.days.length+1, centerLocation: point, points: []})

    $scope.selectDay = (day) ->
      $scope.currentDay = day
      refreshCenterMap()
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
