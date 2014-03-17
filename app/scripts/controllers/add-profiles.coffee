# CoffeeScript
angular.module('kbc.app.External')
  .controller 'AddProfilesController', [
    "$scope"
    'Googleanayticsservice'
    '$timeout'
    '$location'
    '$routeParams'
    ($scope, gaService,$timeout,$location,$routeParams) ->
      $scope.loading = false
      $scope.profiles = []
      $scope.alerts = []
      $scope.selectedProfiles = []
      $scope.isSaving = false
      #$scope.authSuccess = $routeParams.oauth == 'success'
      
      #console.log gaService
      #-----------------------------------
      # Los alertos
      #---------------------------------
      $scope.alerts = []
      $scope.closeAlert = (index) ->
        $scope.alerts.splice(index, 1)
      
      

      $scope.addAlert = (type, msg) ->
        alert = type: type, msg: msg
        $scope.alerts.push(alert)
        $timeout (->
          $scope.closeAlert($scope.alerts.indexOf(alert))
        ), 5000


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
          $location.url('/')
        .error () ->
          $scope.addAlert("danger","Oops, error, saving profiles failed.")
          $scope.isSaving = false
          
            
      $scope.cancel  = () ->
        #alert "TODO!!!"
        #$location.url('/')
        
      
      
      #-----------------------------------
      # remove profile from array
      #---------------------------------
      $scope.removeProfile = (from, profile) ->
        idx = from.indexOf(profile)
        from = from.splice(idx,1)
        
      
      #-----------------------------------
      # un profile
      #---------------------------------
      $scope.unselectProfile = (googleId) ->
        profileToUnselect = _.find($scope.selectedProfiles, (item) ->
          item.googleId == googleId
        )
        if profileToUnselect
          $scope.profiles.push(profileToUnselect)
          $scope.removeProfile($scope.selectedProfiles, profileToUnselect)
          
      #-----------------------------------
      # select profile
      #---------------------------------
      $scope.selectProfile = (profileGoogleId) ->
        profileToAdd = _.find($scope.profiles, (item) ->
          item.googleId == profileGoogleId
        )
        if profileToAdd
          $scope.selectedProfiles.push(profileToAdd)
          $scope.removeProfile($scope.profiles, profileToAdd)
        else
          $scope.addAlert('danger',"Oops, something went wrong selecting the non-existing profile")
      
      #-----------------------------------
      # Parse get profiles reponse
      #---------------------------------
      $scope.parseProfilesResponse = (response) ->
        result = []
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
      
      #-----------------------------------
      # Load profiles from ga
      #---------------------------------
      $scope.loadProfiles = ->
        $scope.loading =true
        $scope.profiles = []
        gaService
        .getProfiles()
        .success (data) ->
          $scope.profiles = $scope.parseProfilesResponse(data)
          $scope.loading = false
        .error () ->
          $scope.loading =false
          $scope.addAlert("danger","Oops, error, could not load profiles for the account")
        
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
        
      #if $scope.authSuccess
      #  $scope.addAlert('success', "Google analytics account configured succesfully")
        
      
      
      
    
  ]