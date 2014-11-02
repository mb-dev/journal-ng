class EventsCollection extends IndexedDbCollection
  getByDynamicFilter: (filter, sortColumns) ->
    processResults = (events) =>
      @sortLazy(events, sortColumns)

    if filter.date
      if filter.date.month? && filter.date.year?
        minDate = moment({month: filter.date.month, year: filter.date.year}).startOf('month').valueOf()
        maxDate = moment({month: filter.date.month, year: filter.date.year}).endOf('month').valueOf()

      @dba.events.query('date').bound(minDate, maxDate).execute().then(processResults)
    else if filter.participantId
      @dba.events.query('participantIds').only(filter.participantId).execute().then(processResults)
    else
      throw new Error("invalid query")

  getItemsByMonthYear: (month, year, sortColumns) ->
    @getByDynamicFilter({date: {month: month, year: year}})

  getEventsByParticipantId: (participantId, sortColumns) ->
    @getByDynamicFilter({participantId}, sortColumns)