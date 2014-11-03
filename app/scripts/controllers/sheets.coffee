angular.module('kbc.app.External')
  .controller('SheetsController', [
    "$scope"
    "$rootScope"
    "kbSapiService"
    "kbc.app.External.config"
    "Gdriveservice"
    "$q"
    "$location"
    "sheetsAndAccount"
    "gdFilesPromise"
    ($scope, $rootScope, storageService, config, gdriveService, $q,$location, sheetsAndAccount, gdFilesPromise) ->

      $scope.gdService = gdriveService
      $scope.account = sheetsAndAccount.account

      $scope.isSaving=false
      $scope.sheets = sheetsAndAccount.sheets
      $scope.gdrive =
        files:[]


      $scope.resolveGdFilesPromise = () ->
        $scope.filesLoading = true
        $scope.gdFilesPromise.then((result) ->
          $scope.filesLoading = false
        , (err) ->
          $scope.filesLoading = false
        )
      $scope.gdFilesPromise = gdFilesPromise.promise
      $scope.resolveGdFilesPromise()

      $scope.refreshFiles = () ->
        $scope.gdFilesPromise = gdriveService.getFilesFromGdrivePromise().promise
        $scope.$broadcast("refreshGdFiles",null)
        $scope.resolveGdFilesPromise()

      $scope.sheetsToSave = []

      #-----------------------------------
      # Load sheets from google drive
      #---------------------------------
      $scope.submit = () ->
        $scope.isSaving=true
        gdriveService
          .storeNewSheets($scope.sheetsToSave)
          .success (data) ->
            $scope.isSaving=false
            $scope.successMessage="Sheets succesfully saved to the configuration."
            $scope.goToIndex()
          .error (error) ->
            $scope.isSaving=false
            $scope.error="Oops,error, saving new sheets failed:"+error.toString()

      #-----------------------------------
      # Refresh Sheets- reload files that have already been loaded
      #---------------------------------
      $scope.refreshFileSheets = (fileIdx) ->
        if $scope.gdrive.files[fileIdx]
          $scope.gdrive.files[fileIdx].isCollapsed = true
        $scope.loadGdriveSheets(fileIdx, true)

      #----------------------------------
      # Go to index page
      #---------------------------------
      $scope.goToIndex = () ->
        $scope.goingtoindex = true
        $location.path "/"




  ])
