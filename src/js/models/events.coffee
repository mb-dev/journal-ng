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