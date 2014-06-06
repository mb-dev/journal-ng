class CalendarEventsCollection extends IndexedDbCollection
  getByDynamicFilter: (filters) =>
    new RSVP.Promise (resolve, reject) =>
      if filters.date
        minDate = moment(filters.date).startOf('month').unix()
        maxDate = moment(filters.date).endOf('month').unix()
        @dba.calEvents.query('date').bound(minDate, maxDate).desc().execute().done (calEvents) =>
          resolve(calEvents)
      else
        resolve([])

  getNextItem: (currentId) =>
    new RSVP.Promise (resolve, reject) =>
      @dba[@collectionName].query('id').lowerBound(currentId).limit(2).execute().done (items) =>
        resolve(items[1])