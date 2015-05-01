'use strict'

# Declare app level module which depends on filters, and services
App = angular.module('app', [
  'ngCookies'
  'ngResource'
  'ngSanitize'
  'app.controllers'
  'app.directives'
  'app.filters'
  'app.services'
  'core.controllers'
  'core.directives'
  'core.filters'
  'ngRoute'
  'angularMoment'
  'mgcrea.ngStrap'
  'checklist-model'
  'monospaced.elastic'
])

App.config ($routeProvider, $locationProvider) ->
  authAndCheckData = (tableList, db, storageService, $rootScope) ->
    setTimeout ->
      if storageService.isAuthenticateTimeAndSet()
        db.getTables(tableList).then (ok) ->
          coffeescript_needs_this_line = true
        , (failure) ->
          $rootScope.$broadcast('auth_fail', failure)
    , 5000
    db

  loadIdbCollections = (otherFunctions = []) ->
    {
      db: ($q, $route, journaldb, storageService, $rootScope) ->
        defer = $q.defer()
        journaldb.preloaded = {}
        journaldb.loadTables().then ->
          async.each otherFunctions, (func, callback) ->
            func(journaldb, $route).then ->
              callback()
            , (err) ->
              console.log "Failed #{err}", err.stack
          , (err) ->
            defer.resolve(journaldb)
          if storageService.isUserExists() and storageService.getEncryptionKey()
            authAndCheckData(Object.keys(journaldb.tables), journaldb, storageService, $rootScope)
        , (err) ->
          console.log "error loading", err.stack
          defer.reject(err)
        defer.promise
    }

  getResolvedPromise = ->
    deferred = RSVP.defer()
    deferred.resolve()
    deferred.promise

  loadCategories = (db) ->
    db.categories().getAllKeys().then (categories) ->
      db.preloaded.categories = categories

  loadPeople = (db) ->
    db.people().getAll().then (people) ->
      db.preloaded.people = people

  loadEventForMemory = (db, $route) ->
    eventId = parseInt($route.current.params.eventId, 10)
    if eventId
      db.events().findById(eventId).then (event) ->
        db.preloaded.event = event
    else
      getResolvedPromise()

  loadParentMemoryForMemory = (db, $route) ->
    parentMemoryId = parseInt($route.current.params.parentMemoryId, 10)
    if parentMemoryId
      db.memories().findById(parentMemoryId).then (parentMemory) ->
        db.preloaded.parentMemory = parentMemory
    else
      getResolvedPromise()

  loadMemory = (db, $route) ->
    itemId = parseInt($route.current.params.itemId, 10)
    db.memories().findById(itemId).then (item) ->
      db.preloaded.item = item

  loadEvent = (db, $route) ->
    itemId = parseInt($route.current.params.itemId, 10)
    db.events().findById(itemId).then (item) ->
      db.preloaded.item = item

  loadPerson = (db, $route) ->
    itemId = parseInt($route.current.params.itemId, 10)
    db.people().findById(itemId).then (item) ->
      db.preloaded.item = item

  $routeProvider
    .when('/', {templateUrl: '/partials/home/welcome.html', controller: 'WelcomePageController', resolve: loadIdbCollections()})

    # memories
    .when('/journal/:year/:month', {templateUrl: '/partials/journal/index.html', controller: 'JournalIndexController', resolve: loadIdbCollections() })
    .when('/journal/', {templateUrl: '/partials/journal/index.html', controller: 'JournalIndexController', resolve: loadIdbCollections() })

    .when('/categories/', {templateUrl: '/partials/categories/index.html', controller: 'CategoriesIndexController', resolve: loadIdbCollections() })

    .when('/memories/new', {templateUrl: '/partials/memories/form.html', controller: 'MemoriesFormController', resolve: loadIdbCollections([loadCategories, loadPeople, loadEventForMemory, loadParentMemoryForMemory]) })
    .when('/memories/addMention', {templateUrl: '/partials/memories/addMention.html', controller: 'MemoriesAddMentionController', resolve: loadIdbCollections() })
    .when('/memories/:itemId/edit', {templateUrl: '/partials/memories/form.html', controller: 'MemoriesFormController', resolve: loadIdbCollections([loadCategories, loadPeople, loadMemory]) })
    .when('/memories/:year/:month', {templateUrl: '/partials/memories/index.html', controller: 'MemoriesIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })
    .when('/memories/:itemId', {templateUrl: '/partials/memories/show.html', controller: 'MemoriesShowController', resolve: loadIdbCollections([loadMemory]) })
    .when('/memories/', {templateUrl: '/partials/memories/index.html', controller: 'MemoriesIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })

    .when('/events/new', {templateUrl: '/partials/events/form.html', controller: 'EventsFormController', resolve: loadIdbCollections([loadCategories, loadPeople]) })
    .when('/events/:itemId/edit', {templateUrl: '/partials/events/form.html', controller: 'EventsFormController', resolve: loadIdbCollections([loadCategories, loadPeople, loadEvent]) })
    .when('/events/:year/:month', {templateUrl: '/partials/events/index.html', controller: 'EventsIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })
    .when('/events/:itemId', {templateUrl: '/partials/events/show.html', controller: 'EventsShowController', resolve: loadIdbCollections([loadEvent]) })
    .when('/events/', {templateUrl: '/partials/events/index.html', controller: 'EventsIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })

    .when('/people/new', {templateUrl: '/partials/people/form.html', controller: 'PeopleFormController', resolve: loadIdbCollections([loadCategories]) })
    .when('/people/:itemId/edit', {templateUrl: '/partials/people/form.html', controller: 'PeopleFormController', resolve: loadIdbCollections([loadCategories, loadPerson]) })
    .when('/people/', {templateUrl: '/partials/people/index.html', controller: 'PeopleIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })
    .when('/people/:itemId', {templateUrl: '/partials/people/show.html', controller: 'PeopleShowController', resolve: loadIdbCollections([loadPerson]) })

    .when('/schedule/:itemId/edit', {templateUrl: '/partials/schedule/form.html', controller: 'ScheduleFormController', resolve: loadIdbCollections() })
    .when('/schedule/:year/:month', {templateUrl: '/partials/schedule/index.html', controller: 'ScheduleIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })
    .when('/schedule/:itemId', {templateUrl: '/partials/schedule/show.html', controller: 'ScheduleShowController', resolve: loadIdbCollections() })
    .when('/schedule/', {templateUrl: '/partials/schedule/index.html', controller: 'ScheduleIndexController', reloadOnSearch: false, resolve: loadIdbCollections() })

    .when('/misc', {templateUrl: '/partials/misc/index.html', controller: 'MiscController', resolve: loadIdbCollections() })

    .when('/todo/', {templateUrl: '/partials/todo/index.html', controller: 'ToDoIndexController', reloadOnSearch: false })

    .when('/maps/', {templateUrl: '/partials/maps/index.html', controller: 'MapsIndexController'})

    .when('/login_success', template: 'Loading...', controller: 'LoginOAuthSuccessController')
    .when('/key', {templateUrl: '/partials/user/key.html', controller: 'UserKeyController', resolve:  loadIdbCollections() })
    .when('/profile', {templateUrl: '/partials/user/profile.html', controller: 'UserProfileController', resolve:  loadIdbCollections() })
    .when('/edit_profile', {templateUrl: '/partials/user/edit_profile.html', controller: 'UserEditProfileController'})
    .when('/logout', {template: 'Logging out...', controller: 'UserLogoutController'})

    # Catch all
    .otherwise({redirectTo: '/'})

  # Without server side support html5 must be disabled.
  $locationProvider.html5Mode(true)

App.run ($rootScope, $location, $injector, $window, $timeout, storageService, userService) ->
  redirectOnFailure = (failure) ->
    if failure.reason == 'not_logged_in'
      storageService.onLogout()
      $location.path '/?refresh'
    else if failure.reason == 'missing_key'
      $location.path '/key'

  $rootScope.appName = 'Journal'
  $rootScope.domain = 'journal'
  $rootScope.headerPath = '/partials/common/memory_header.html'
  $rootScope.loginUrl = userService.oauthUrl($rootScope.domain)
  storageService.setAppName($rootScope.appName, $rootScope.domain)

  $rootScope.$on "$routeChangeError", (event, current, previous, rejection) ->
    if rejection.data.reason
      redirectOnFailure(rejection.data)

  $rootScope.$on '$routeChangeStart', ->
    $rootScope.currentLocation = $location.path()

    if storageService.getSuccessMsg()
      $rootScope.successMsg = storageService.getSuccessMsg()
    if storageService.getNoticeMsg()
      $rootScope.noticeMsg = storageService.getNoticeMsg()
    storageService.clearMsgs()
    $rootScope.userDetails = storageService.getUserDetails()
    $rootScope.loggedIn = $rootScope.userDetails?
    if $rootScope.userDetails
      $rootScope.userDetails.firstName = $rootScope.userDetails.name.split(' ')[0]

  $rootScope.$on 'auth_fail', (event, failure) ->
    if failure.data.reason
      redirectOnFailure(failure.data)

  modals = []
  $rootScope.$on 'modal.show', (e, $modal) ->
    if modals.indexOf($modal) == -1
      modals.push($modal);

  $rootScope.$on '$routeChangeSuccess', ->
    if modals.length
      angular.forEach modals, ($modal) ->
        $modal.$promise.then($modal.destroy);

  $rootScope.isActive = (urlPart) =>
    $location.path().indexOf(urlPart) > 0
  $rootScope.flashSuccess = (msg) ->
    storageService.setSuccessMsg(msg)
  $rootScope.flashNotice = (msg) ->
    storageService.setNoticeMsg(msg)
  $rootScope.showSuccess = (msg) ->
    $rootScope.successMsg = msg
  $rootScope.showError = (msg) ->
    $rootScope.errorMsg = msg
  $rootScope.setTitle = (title) ->
    $window.document.title = $rootScope.appName + ' - ' + title

  $rootScope.$on '$viewContentLoaded', ->
    storageService.clearMsgs()
