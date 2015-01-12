# CoffeeScript
angular.module('kbc.app.External')
  .controller 'AddProfilesController', [
    "$scope"
    'Googleanayticsservice'
    '$timeout'
    '$location'
    '$routeParams'
    '$q'
    ($scope, gaService,$timeout,$location,$routeParams, $q) ->
      $scope.loading = false
      $scope.profiles = []
      $scope.alerts = []
      $scope.selectedProfiles = []
      $scope.isSaving = false
      $scope.authSuccess = $routeParams.oauth == 'success'
      $scope.search =
        q: ''

      $scope.filterQueries = (queries) ->
        q = $scope.search.q
        result = {}


      $scope.configName = gaService.getConfigName()
      #console.log gaService

      $scope.goToIndex = ->
        $location.path('/')

      $scope.unselectProfileEx = (profile) ->
        profile.selected = false
        $scope.selectedProfiles = _.filter $scope.selectedProfiles, (p) ->
          isFiltered = p.googleId != profile.googleId and profile.name != p.name
          return isFiltered
        $scope.markSelected(profile,false)
      $scope.markSelected = (profile, selected) ->
        root = $scope.rawProfiles[profile.accountName]
        if not root
          return
        property = root[profile.webPropertyName]
        if not property
          return
        item = _.find(property, (p) -> p.name == profile.name)
        if item
          item.selected = selected


      $scope.selectProfileEx = (key, propname, item) ->
        name = item['name']
        itemToPush =
          googleId : item.id
          accountId : item.accountId
          webPropertyId : item.webPropertyId
          name : name
          accountName: key
          webPropertyName: propname
          selected: true

        if item.selected
          $scope.unselectProfileEx(itemToPush)
        else
          item.selected = true
          $scope.selectedProfiles.push itemToPush



      #-----------------------------------
      # submit
      #---------------------------------
      $scope.submit = ->
        if not $scope.profiles
          return
        $scope.isSaving = true
        gaService
        .postProfiles($scope.selectedProfiles)
        .success (data) ->
          $scope.addAlert("success","New profiles succesfully saved.")
          $scope.isSaving = false
          $scope.goingToIndex = true
          gaService.goToIndex()
        .error () ->
          $scope.addAlert("danger","Oops, error, saving profiles failed.")
          $scope.isSaving = false

      $scope.cancel  = () ->
        #alert "TODO!!!"
        $location.path('/')


      #-----------------------------------
      # remove profile from array
      #---------------------------------
      $scope.removeProfile = (from, profile) ->
        idx = from.indexOf(profile)
        from = from.splice(idx,1)


      # #-----------------------------------
      # # un profile
      # #---------------------------------
      # $scope.unselectProfile = (googleId) ->
      #   profileToUnselect = _.find($scope.selectedProfiles, (item) ->
      #     item.googleId == googleId
      #   )
      #   if profileToUnselect
      #     $scope.profiles.push(profileToUnselect)
      #     $scope.removeProfile($scope.selectedProfiles, profileToUnselect)

      # #-----------------------------------
      # # select profile
      # #---------------------------------
      # $scope.selectProfile = (profileGoogleId) ->
      #   profileToAdd = _.find($scope.profiles, (item) ->
      #     item.googleId == profileGoogleId
      #   )
      #   if profileToAdd
      #     $scope.selectedProfiles.push(profileToAdd)
      #     $scope.removeProfile($scope.profiles, profileToAdd)
      #   else
      #     $scope.addAlert('danger',"Oops, something went wrong selecting the non-existing profile")

      #-----------------------------------
      # Parse get profiles reponse
      #---------------------------------
      $scope.parseProfilesResponse = (response) ->
        result = []
        console.log response
        for key,value of response
            for key2,value2 of value
              result = result.concat( _.map( value2, (item) ->
                res = {}
                res.googleId = item.id
                res.accountId = item.accountId
                res.webPropertyId = item.webPropertyId
                res.name = item.name
                res
                ))
        result


      $scope.account = {}
      #-----------------------------------
      # Load profiles from ga
      #---------------------------------
      $scope.loadProfiles = ->
        $scope.loading =true
        $scope.profiles = []
        queriesp = gaService.loadQueriesAndSavedProfiles().then (data) ->
          $scope.account = data

        profilesp = gaService
        .getProfiles()
        .success (data) ->
          $scope.profiles = $scope.parseProfilesResponse(data)
          $scope.rawProfiles = data
          $scope.loading = false

        .error () ->
          $scope.loading =false
          $scope.addAlert("danger","Oops, error, could not load profiles for the account")
        $q.all([queriesp,profilesp]).then () ->
          for p in $scope.account.profiles
            $scope.selectedProfiles.push p
            $scope.markSelected(p, true)

      $scope.loadProfiles()


      #-----------------------------------
      # Los alertos
      #---------------------------------
      $scope.closeAlert = (index) ->
        $scope.alerts.splice(index, 1)


      $scope.addAlert = (type, msg) ->
        alert = type: type, msg: msg
        $scope.alerts.push(alert)
        $timeout (->
          $scope.closeAlert($scope.alerts.indexOf(alert))
        ), 5000

      if $scope.authSuccess
        $scope.addAlert('success', "Google analytics account configured succesfully")





  ]
