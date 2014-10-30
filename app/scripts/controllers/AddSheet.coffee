angular.module('kbc.app.External')
  .controller('AddsheetController', [
    "$scope"
    "$rootScope"
    "kbSapiService"
    "kbc.app.External.config"
    "Gdriveservice"
    "$q"
    "$location"
    "$timeout"
    ($scope, $rootScope, storageService, config, gdriveService, $q,$location,$timeout) ->

      $scope.filesLoading = false
      $scope.isSaving=false

      $scope.currentSheets = []
      $scope.account = {}
      $scope.gdrive =
        files:[]
      $scope.global =
        loading : false

      $scope.setLoading = (param) ->
        if param is undefined or param is null
          $scope.filesLoading = !scope.filesLoading
        else
          $scope.filesLoading = param
        $scope.global.loading = $scope.filesLoading

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
      # init
      # loads configured sheets and account and sheets from gdrive
      #---------------------------------
      $scope.init = () ->
        $scope.setLoading(true)
        gdriveService
          .loadSavedSheetsListAndAccount()
          .then (data) ->
            #first we load the list of currently saved sheets
            $scope.currentSheets = _.map(data.sheets, (item) ->
              res =
                sheetId:  item.sheetId
                googleId: item.googleId
              res
              )
            $scope.account = data.account
            $scope.loadGdriveFiles()
          , (error) ->
            $scope.setLoading(false)
            []

      $scope.locked = 0

      #-----------------------------------
      # Load sheets from google drive
      #---------------------------------
      $scope.submit = () ->
        result = []
        angular.forEach($scope.gdrive.files, (file) ->
          result = result.concat(_.filter(file.sheets, (sheet) ->
            sheet and sheet.added and not sheet.disabled
            )
          )
        )
        $scope.isSaving=true
        gdriveService
          .storeNewSheets(result)
          .success (data) ->
            $scope.isSaving=false
            $scope.addAlert("success","New sheet(s) have been succesfully added.")
            $scope.goToIndex(true)

          .error (error) ->
            $scope.isSaving=false
            $scope.error="Oops,error, saving new sheets failed:"+error.toString()






      #-----------------------------------
      # is Expanding
      #---------------------------------
      $scope.isExpanding = () ->
        $scope.locked > 0


      #-----------------------------------
      # lock expansion
      #---------------------------------
      $scope.lockExpansion= ()  ->
        locked = $scope.isExpenading
        if not locked
          $scope.locked = $scope.gdrive.files.length
        return locked


      #-----------------------------------
      # unlock expansion
      #---------------------------------
      $scope.unlockExpansion = () ->
        if $scope.locked > 0
          $scope.locked = $scope.locked - 1

      #-----------------------------------
      # Expand All - show all files sheets
      #---------------------------------
      $scope.selectAll = ()->
        if $scope.isExpanding()
          return
        $scope.lockExpansion()

        angular.forEach($scope.gdrive.files, (file,fileidx) ->
          def = $q.defer()
          if not file.loaded
            $scope.loadGdriveSheets(fileidx, false).then( () ->
              def.resolve(file)
            )
          else
            def.resolve(file)
          def.promise.then (f) ->

            f.isCollapsed= false
            angular.forEach file.sheets, (sheet) ->
              if not sheet.disabled
                sheet.added = !sheet.added
            $scope.unlockExpansion()
         )

      #-----------------------------------
      # Expand All - show all files sheets
      #---------------------------------
      $scope.expandAll = () ->
        if $scope.isExpanding()
          return
        $scope.lockExpansion()

        angular.forEach($scope.gdrive.files, (file,fileidx) ->
            $scope.loadGdriveSheets(fileidx, false)
        )

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
      $scope.goToIndex = (reloadSheets) ->
        #authSucess var changes views
        $location.url('/')
        #if reloadSheets
        #  $rootScope.$broadcast('reloadSheets')




      #-----------------------------------
      # Load sheets from google drive
      #---------------------------------
      $scope.loadGdriveSheets = (fileidx, forceLoad ) ->
        file = $scope.gdrive.files[fileidx]

        #we dont want to collapse when refresh icon is beign clicked
        if not forceLoad
          if not file.isCollapsed
            file.isCollapsed = true
          else
            if file.loaded
              file.isCollapsed = false

        if (file.loaded and not forceLoad)  or file.loading
          $scope.unlockExpansion()
          return

        file.loading = true
        fileId = $scope.gdrive.files[fileidx].id
        gdriveService
          .getSheetsFromGdrive(fileId)
          .success((data) ->
            $scope.unlockExpansion()
            file.loading = false
            file.sheets = data

            #we add new property for checkbox ng-model
            file.sheets = _.map(file.sheets, (item) ->
              res = {}
              res.sheetTitle = item.title
              res.title = file.title
              res.added = false
              res.disabled = _.find($scope.currentSheets, (sheetp)->
                sheetp.sheetId == item.id.toString() and sheetp.googleId == file.id)?
              res.googleId = file.id
              res.sheetId = item.id
              res.tooltip = if item.disabled then "Already added for the extraction" else "Select to add for extraction"
              #item.accountId = gdriveAccount.id
              res
            )
            file.loaded = true
            file.isCollapsed = !file.isCollapsed
          )
          .error((error) ->

            file.loading = false
          )



      #-----------------------------------
      # Load files from google drive
      #-------------------------------
      $scope.loadGdriveFiles = () ->
        $scope.setLoading(true)
        gdriveService
          .getFilesFromGdrive()
          .success((data) ->
            $scope.setLoading(false)
            $scope.gdrive.files = data.items
            $scope.gdrive.files = _.map($scope.gdrive.files,(item) ->
              item.sheets=null
              item.loading= false
              item.loaded = false
              item.isCollapsed = true
              item
            )
          )
          .error((error) ->
            $scope.setLoading(false)
          )

      $scope.init()


  ])
