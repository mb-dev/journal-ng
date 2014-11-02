angular.module('app.controllers')
  .controller 'CategoriesIndexController', ($scope, $routeParams, $location, db) ->
    items = []

    db.memories().getAllParentMemories().then (memories) ->
      db.events().getAll().then (events) -> $scope.$apply ->
        memories.forEach (item) ->
          item.categories.forEach (categoryName) ->
            items.push({categoryName: categoryName, type: 'memories', modifiedAt: item.modifiedAt, data: item, itemDate: item.date, date: moment(item.modifiedAt).format('L')})
        events.forEach (item) ->
          item.categories.forEach (categoryName) ->
            items.push({categoryName: categoryName, type: 'events', modifiedAt: item.modifiedAt, data: item, itemDate: item.date, date: moment(item.modifiedAt).format('L')})

        categoryData = _.groupBy(items, 'categoryName')
        categories = _(categoryData).keys().uniq().sortBy(_.identity).valueOf()

        categories.forEach (item) ->
          if categoryData[item].length == 0
            delete categoryData[item]
          else
            categoryData[item] = _.sortBy(categoryData[item], 'itemDate').reverse()

        $scope.categories = categories
        $scope.categoryData = categoryData
    return
