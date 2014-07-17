 angular.module('app.services')
  .factory 'mdb', ($q, storageService, userService) ->
    tablesList = {
      memories: 'memories'
      events: 'events'
      people: 'people'
      categories: 'categories'
    }
    db = new Database('memoryng', $q, storageService, userService)
    tables = {
      memories: db.createCollection(tablesList.memories, new MemoriesCollection($q, ['date', 'id']))
      events: db.createCollection(tablesList.events, new EventsCollection($q, 'date'))
      people: db.createCollection(tablesList.people, new Collection($q,'name')),
      categories: db.createCollection(tablesList.categories, new SimpleCollection($q))
    }

    # events
    tables.events.setItemExtendFunc (item) ->
      item.$participants = ->
        getAll: ->
          tables.people.findByIds(item.participantIds)
      item.$memories = ->
        getAll: ->
          tables.memories.getItemsByEventId(item.id)
      item.$mentioned = ->
        getAll: ->
          tables.memories.getMemoriesMentionedAtEventId(item.id)

    tables.people.setItemExtendFunc (item) ->
      item.$mentioned = ->
        getAll: ->
          tables.memories.getMemoriesMentionedToPersonId(item.id)

    accessFunc = {
      tables: tablesList
      memories: ->
        tables.memories
      events: ->
        tables.events
      people: ->
        tables.people
      categories: ->
        tables.categories
      config: ->
        {}
      createAllFiles: (tableNames) ->
        db.createAllFiles(tableNames)
      authAndCheckData: (tableList) =>
        db.authAndCheckData(tableList)
      getTables: (tableList, forceRefreshAll) =>
        db.getTables(tableList, forceRefreshAll)
      saveTables: (tableList, forceServerCleanAndSaveAll) ->
        db.saveTables(tableList, forceServerCleanAndSaveAll)
      dumpAllCollections: (tableList) -> 
        db.dumpAllCollections(tableList)
    }