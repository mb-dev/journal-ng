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
  'ui.select2'
  'siyfion.sfTypeahead'
  'checklist-model'
])

App.config ($routeProvider, $locationProvider) ->
  authAndCheckData = (tableList, db, storageService, $rootScope) ->
    setTimeout ->
      if storageService.isAuthenticateTimeAndSet()
        db.authAndCheckData(tableList).then (ok) ->
          coffeescript_needs_this_line = true
        , (failure) ->
          console.log 'failed to get latest data', failure
          $rootScope.$broadcast('auth_fail', failure)
    , 5000
    db

  resolveMDb = (tableList, allowLoggedOut) ->
    {
      db: ($q, mdb, storageService, $rootScope) -> 
        defer = $q.defer()
        if allowLoggedOut && !storageService.isUserExists()
          defer.resolve(null)
        else
          mdb.getTables(tableList(mdb)).then -> 
            authAndCheckData(Object.keys(mdb.tables), mdb, storageService, $rootScope)
            defer.resolve(mdb)
          , (err) ->
            defer.reject(err)
        defer.promise

    }

  memoryNgAllDb = (mdb) -> [mdb.tables.memories, mdb.tables.events, mdb.tables.people, mdb.tables.categories]
  
  $routeProvider
    .when('/', {templateUrl: '/partials/home/welcome.html', controller: 'WelcomePageController', resolve: resolveMDb(memoryNgAllDb, true)})

    # memories
    .when('/journal/:year/:month', {templateUrl: '/partials/journal/index.html', controller: 'JournalIndexController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/journal/', {templateUrl: '/partials/journal/index.html', controller: 'JournalIndexController', resolve: resolveMDb(memoryNgAllDb) })

    .when('/categories/', {templateUrl: '/partials/categories/index.html', controller: 'CategoriesIndexController', resolve: resolveMDb(memoryNgAllDb) })

    .when('/memories/new', {templateUrl: '/partials/memories/form.html', controller: 'MemoriesFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/memories/addMention', {templateUrl: '/partials/memories/addMention.html', controller: 'MemoriesAddMentionController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/memories/:itemId/edit', {templateUrl: '/partials/memories/form.html', controller: 'MemoriesFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/memories/:year/:month', {templateUrl: '/partials/memories/index.html', controller: 'MemoriesIndexController', reloadOnSearch: false, resolve: resolveMDb(memoryNgAllDb) })
    .when('/memories/:itemId', {templateUrl: '/partials/memories/show.html', controller: 'MemoriesShowController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/memories/', {templateUrl: '/partials/memories/index.html', controller: 'MemoriesIndexController', reloadOnSearch: false, resolve: resolveMDb(memoryNgAllDb) })

    .when('/events/new', {templateUrl: '/partials/events/form.html', controller: 'EventsFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/events/:itemId/edit', {templateUrl: '/partials/events/form.html', controller: 'EventsFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/events/:year/:month', {templateUrl: '/partials/events/index.html', controller: 'EventsIndexController', reloadOnSearch: false, resolve: resolveMDb(memoryNgAllDb) })
    .when('/events/:itemId', {templateUrl: '/partials/events/show.html', controller: 'EventsShowController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/events/', {templateUrl: '/partials/events/index.html', controller: 'EventsIndexController', reloadOnSearch: false, resolve: resolveMDb(memoryNgAllDb) })

    .when('/people/new', {templateUrl: '/partials/people/form.html', controller: 'PeopleFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/people/:itemId/edit', {templateUrl: '/partials/people/form.html', controller: 'PeopleFormController', resolve: resolveMDb(memoryNgAllDb) })
    .when('/people/', {templateUrl: '/partials/people/index.html', controller: 'PeopleIndexController', reloadOnSearch: false, resolve: resolveMDb(memoryNgAllDb) })
    .when('/people/:itemId', {templateUrl: '/partials/people/show.html', controller: 'PeopleShowController', resolve: resolveMDb(memoryNgAllDb) })

    .when('/login_success', template: 'Loading...', controller: 'LoginOAuthSuccessController')
    .when('/key', {templateUrl: '/partials/user/key.html', controller: 'UserKeyController', resolve:  {db: (mdb) -> mdb}})
    .when('/profile', {templateUrl: '/partials/user/profile.html', controller: 'UserProfileController', resolve:  {db: (mdb) -> mdb} })
    .when('/edit_profile', {templateUrl: '/partials/user/edit_profile.html', controller: 'UserEditProfileController'})
    .when('/logout', {template: 'Logging out...', controller: 'UserLogoutController'})

    # Catch all
    .otherwise({redirectTo: '/'})

  # Without server side support html5 must be disabled.
  $locationProvider.html5Mode(true)

App.run ($rootScope, $location, $injector, $timeout, storageService, userService) ->
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

  $rootScope.$on '$viewContentLoaded', ->
    storageService.clearMsgs()