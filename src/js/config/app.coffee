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
  'ngRoute'
  'angularMoment'
  'ui.select2',
  'fileSystem',
  'siyfion.sfTypeahead'
  'checklist-model'
])

App.config ($routeProvider, $locationProvider) ->
  authAndCheckData = (tableList, db) ->
    setTimeout ->
      $injector = angular.element('ng-view').injector()
      storageService = $injector.get('storageService')
      if storageService.isAuthenticateTimeAndSet()
        db.authAndCheckData(tableList(db)).then (ok) ->
          coffeescript_needs_this_line = true
        , (failure) ->
          $injector.get('$rootScope').$broadcast('auth_fail', failure)
    , 5000
    db

  resolveFDb = (tableList) ->
    {
      db: (fdb) -> 
        fdb.getTables(tableList(fdb)).then -> authAndCheckData(tableList, fdb)
    }

  resolveMDb = (tableList) ->
    {
      db: (mdb) -> 
        mdb.getTables(tableList(mdb)).then -> authAndCheckData(tableList, mdb)
    }

  memoryNgAllDb = (mdb) -> [mdb.tables.memories, mdb.tables.events, mdb.tables.people, mdb.tables.categories]
  
  $routeProvider
    .when('/', {templateUrl: '/partials/home/welcome.html', controller: 'WelcomePageController'})

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
    .when('/login', {templateUrl: '/partials/user/login.html', controller: 'UserLoginController'})
    .when('/key', {templateUrl: '/partials/user/key.html', controller: 'UserKeyController'})
    .when('/register', {templateUrl: '/partials/user/register.html', controller: 'UserLoginController'})
    .when('/profile', {templateUrl: '/partials/user/profile.html', controller: 'UserProfileController' })
    .when('/edit_profile', {templateUrl: '/partials/user/edit_profile.html', controller: 'UserEditProfileController'})
    .when('/logout', {template: 'Logging out...', controller: 'UserLogoutController'})

    # Catch all
    .otherwise({redirectTo: '/'})

  # Without server side support html5 must be disabled.
  $locationProvider.html5Mode(true)

App.run ($rootScope, $location, $injector, $timeout, storageService) ->
  $rootScope.appName = 'memoryNg'

  $rootScope.$on "$routeChangeError", (event, current, previous, rejection) ->
    if rejection.status == 403 && rejection.data.reason == 'not_logged_in'
      $location.path '/login'

    if rejection.status == 403 && rejection.data.reason == 'missing_key'
      $location.path '/key'
  
  $rootScope.$on '$routeChangeStart', ->
    $rootScope.currentLocation = $location.path()
    $sessionStorage = $injector.get('$sessionStorage')
    if $sessionStorage.successMsg
      $rootScope.successMsg = $sessionStorage.successMsg
    if $sessionStorage.noticeMsg
      $rootScope.noticeMsg = $sessionStorage.noticeMsg
    $sessionStorage.successMsg = null
    $sessionStorage.noticeMsg = null
    $rootScope.userDetails = storageService.getUserDetails()
    if $rootScope.userDetails
      $rootScope.userDetails.firstName = $rootScope.userDetails.name.split(' ')[0]

  $rootScope.$on 'auth_fail', ->
    $rootScope.flashNotice('You were logged out on the server, please login again')
    $location.path '/login'

  $rootScope.isActive = (urlPart) =>
    $location.path().indexOf(urlPart) > 0

  $rootScope.flashSuccess = (msg) ->
    $sessionStorage = $injector.get('$sessionStorage')
    $sessionStorage.successMsg = msg

  $rootScope.flashNotice = (msg) ->
    $sessionStorage = $injector.get('$sessionStorage')
    $sessionStorage.noticeMsg = msg

  $rootScope.$on '$viewContentLoaded', ->
    $sessionStorage = $injector.get('$sessionStorage')
    $sessionStorage.successMsg = null
    $sessionStorage.errorMsg = null  