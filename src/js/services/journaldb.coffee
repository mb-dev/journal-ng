 angular.module('app.services')
  .factory 'journaldb', ($q, storageService, userService) ->
    tablesList = {
      calEvents: 'calEvents'
    }
    db = new IndexedDbDatabase('memoryng', $q, storageService, userService)
    tables = {}

    tables.calEvents = db.createCollection('calEvents', new CalendarEventsCollection('memoryng', 'calEvents'))
    
    loadTables = ->
      tables.calEvents.createDatabase({
        calEvents:
          key: { keyPath: 'id' }
          indexes:
            id: {unique: true}
            date: {}
            gcalId: {unique: true}
      }, 1)

    accessFunc = {
      tables: tablesList
      calendarEvents: ->
        tables.calEvents
      loadTables: ->
        loadTables()
      config: ->
        {}
      getTables: (tableList, forceRefreshAll) =>
        db.getTables(tableList, forceRefreshAll)
      saveTables: (tableList, forceServerCleanAndSaveAll) ->
        db.saveTables(tableList, forceServerCleanAndSaveAll)
    }