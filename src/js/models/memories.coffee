class MemoriesCollection extends IndexedDbCollection

  migrateIfNeeded: ->

  getByDynamicFilter: (filter, sortColumns) ->
    processResults = (memories) =>
      memories = _.filter(memories, (item) -> 
        if filter.onlyParents
          return false if item.parentMemoryId || (item.events && item.events.length > 0)
        true
      )
      @sortLazy(memories, sortColumns)

    if filter.date
      if filter.date.month? && filter.date.year?
        minDate = moment({month: filter.date.month, year: filter.date.year}).startOf('month').valueOf()
        maxDate = moment({month: filter.date.month, year: filter.date.year}).endOf('month').valueOf()

      @dba.memories.query('date').bound(minDate, maxDate).execute().then(processResults)
    else if filter.parentMemoryId
      @dba.memories.query('parentMemoryId').only(filter.parentMemoryId).execute().then(processResults)
    else if filter.eventId
      @dba.memories.query('events').only(filter.eventId).execute().then(processResults)
    else if filter.mentionedAtEventId
      @dba.memories.query('mentionedIn').only(filter.mentionedAtEventId).execute().then(processResults)
    else if filter.mentionedToPersonId
      @dba.memories.query('mentionedTo').only(filter.mentionedToPersonId).execute().then(processResults)
    else if filter.personId
      @dba.memories.query('people').only(filter.personId).execute().then(processResults)
    else
      @dba.memories.query().all().execute().then(processResults)

  # getAllCategories: ->
  #   req = indexedDB.open('memoryng')
  #   req.onsuccess = (e) ->
  #     db = e.target.result
  #     transaction = db.transaction('memories', 'readonly')
  #     store = transaction.objectStore('memories')
  #     index = store.index('categories')
  #     req = index.getAllKeys()
  #     req.onsuccess = (e) ->
  #       console.log(e.result)


  getItemsByMonthYear: (month, year, sortColumns) ->
    @getByDynamicFilter({date: {month: month, year: year}})

  getItemsByEventId: (eventId, sortColumns) ->
    @getByDynamicFilter({eventId: eventId})

  getItemsByParentMemoryId: (parentMemoryId, sortColumns) ->
    @getByDynamicFilter({parentMemoryId: parentMemoryId})

  getMemoriesByPersonId: (personId, sortColumns) ->
    @getByDynamicFilter({personId: personId}, sortColumns)

  getAllParentMemories: (sortColumns) ->
    @getByDynamicFilter({onlyParents: true}, sortColumns)

  getMemoriesMentionedAtEventId: (eventId, sortColumns) ->
    @getByDynamicFilter({mentionedAtEventId: eventId}, sortColumns)

  getMemoriesMentionedToPersonId: (personId, sortColumns) ->
    @getByDynamicFilter({mentionedToPersonId: personId}, sortColumns)