class MemoriesCollection extends Collection

  migrateIfNeeded: ->

  getByDynamicFilter: (filter, sortColumns) ->
    results = Lazy(@collection).filter((item) -> 
      if filter.date
        date = moment(item.date)
        return false if !(date.month() == filter.date.month && date.year() == filter.date.year)
      if filter.onlyParents
        return false if item.parentMemoryId || (item.events && item.events.length > 0)
      true
    )
    @sortLazy(results, sortColumns)

  getItemsByMonthYear: (month, year, sortColumns) ->
    results = Lazy(@collection).filter((item) -> 
      date = moment(item.date)
      date.month() == month && date.year() == year
    )
    @sortLazy(results, sortColumns)

  getItemsByEventId: (eventId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.events && item.events.indexOf(eventId) >= 0 )
    @sortLazy(results, sortColumns)

  getItemsByParentMemoryId: (parentMemoryId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.parentMemoryId == parentMemoryId)
    @sortLazy(results, sortColumns)

  getMemoriesByPersonId: (personId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.people && item.people.indexOf(personId) >= 0 )
    @sortLazy(results, sortColumns)

  getAllParentMemories: (sortColumns) ->
    results = Lazy(@collection).filter((item) -> !item.parentMemoryId && (!item.events || item.events.length == 0) )
    @sortLazy(results, sortColumns)

  getMemoriesMentionedAtEventId: (eventId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.mentionedIn && item.mentionedIn.indexOf(eventId) >= 0 )
    @sortLazy(results, sortColumns)

  getMemoriesMentionedToPersonId: (personId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.mentionedTo && item.mentionedTo.indexOf(personId) >= 0 )
    @sortLazy(results, sortColumns)

class EventsCollection extends Collection
  getItemsByMonthYear: (month, year, sortColumns) ->
    results = Lazy(@collection).filter((item) -> 
      date = moment(item.date)
      date.month() == month && date.year() == year
    )
    @sortLazy(results, sortColumns)

  getEventsByParticipantId: (participantId, sortColumns) ->
    results = Lazy(@collection).filter((item) -> item.participantIds && item.participantIds.indexOf(participantId) >= 0 )
    @sortLazy(results, sortColumns)

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