
angular.module('kbc.app.External')
  .controller('IndexController', [
    "$scope"
    "kbSapiService"
    "kbc.app.External.config"
    "$timeout"
    ($scope, storageService, config,$timeout) ->
      
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
        
      

  ])