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