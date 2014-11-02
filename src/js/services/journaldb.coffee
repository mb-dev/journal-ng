APP_NAME = 'memoryng'

angular.module('app.services')
  .factory 'journaldb', ($q, storageService, userService) ->
    db = new IndexedDbDatabase(APP_NAME, $q, storageService, userService)
    tables = {}

    tables.calEvents = db.createCollection('calEvents', new CalendarEventsCollection(APP_NAME, 'calEvents'))
    tables.memories = db.createCollection('memories', new MemoriesCollection(APP_NAME, 'memories', ['date', 'id']))
    tables.events = db.createCollection('events', new EventsCollection(APP_NAME, 'events', ['date', 'id']))
    tables.people = db.createCollection('people', new IndexedDbCollection(APP_NAME, 'people'))
    tables.categories = db.createCollection('categories', new IndexedDbSimpleCollection(APP_NAME, 'categories'))

    tableNames = {}
    tableNames[name] = name for name, item of tables
    
    schema = {
      calEvents:
        key: { keyPath: 'id' }
        indexes:
          id: {unique: true}
          date: {}
          gcalId: {unique: true}
      categories:
        key: { keyPath: 'id' }
        indexes:
          id: {unique: true}
      memories:
        key: { keyPath: 'id' }
        indexes:
          id: {unique: true}
          date: {}
          events: {multiEntry: true}
          categories: {multiEntry: true}
          people: {multiEntry: true}
          parentMemoryId: {}
          mentionedIn: {multiEntry: true}
          mentionedTo: {multiEntry: true}
      events:
        key: { keyPath: 'id' }
        indexes:
          id: {unique: true}
          date: {}
          participantIds: {multiEntry: true}
          categories: {multiEntry: true}
      people:
        key: { keyPath: 'id' }
        indexes:
          id: {unique: true}
          categories: {multiEntry: true}
          interests: {multiEntry: true}
    }

    loadTables = ->
      new RSVP.Promise (resolve, reject) =>
        async.each Object.keys(tables), (table, callback) -> 
          tables[table].createDatabase(schema, 1)
          .then -> tables[table].afterLoadCollection()
          .then(callback)
        , (err) ->
          if err then reject(err) else resolve()

    accessFunc = {
      tables: tableNames,
      preloaded: {}
      calendarEvents: ->
        tables.calEvents
      categories: ->
        tables.categories
      events: ->
        tables.events
      memories: ->
        tables.memories
      people: ->
        tables.people
      loadTables: ->
        loadTables()
      getTables: (tableList, forceRefreshAll) =>
        db.getTables(tableList, forceRefreshAll)
      saveTables: (tableList, forceServerCleanAndSaveAll) ->
        db.saveTables(tableList, forceServerCleanAndSaveAll)
    }