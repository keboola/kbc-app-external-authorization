angular.module('kbc.app.External')
  .directive('googleDriveSpreadsheets',[ () ->
    templateUrl:'views/templates/google-drive-spreadsheets.html'
    restrict:'E'
    scope:
      ownerEmail:"@"
      gdService:"="
      gdriveFilesPromise:"&"
      alreadyConfigured:"="
      sheetsToSave:"="

    controller: ['$scope', ($scope) ->

      $scope.sheetsToSave = []
      $scope.configured = [] #sheets already configured in the project

      $scope.refreshFileSheets = (file) ->
        file.isopen = !file.isopen
        file.loaded = false
        $scope.loadFileSheetsDetail(file)

      #,--------------------------------
      #| load sheet detail
      #`--------------------------------
      $scope.loadFileSheetsDetail = (file) ->
        if (file.loaded or file.loading)
          return
        file.loading = true
        file.error = undefined
        $scope.gdService.getSheetsFromGdrive(file.id).success (result) ->
          file.loaded = true
          file.loading = false
          file.sheets = _.map(result, (sheet) ->
            found = _.find($scope.configured, (cs) ->
              cs.googleId == file.id and cs.sheetId == sheet.id.toString()
            ) or null
            sheet.sheetTitle = sheet.title
            sheet.title = file.title
            sheet.googleId = file.id
            sheet.sheetId = sheet.id
            sheet.inProject = true
            if found == null or found == undefined
              sheet.inProject = false
            return sheet
          )
          file
        .error (err) ->
          file.error = "Failed to load sheets for the spreadshet."
          file.loading = false

      #,--------------------------------
      #| is empty object or array
      #`--------------------------------
      $scope.empty = (file)->
        _.size(file) == 0


      # click on close button in selected
      $scope.deselectSheet = (sheet) ->
        sheet.selected = false
        $scope.sheetsToSave = _.filter($scope.sheetsToSave, (item) ->
          not (item.googleId == sheet.googleId and item.id == sheet.id )
        )

      #,------------------------------------
      #| click on sheet under file accordion
      #`------------------------------------
      $scope.selectSheet = (tab, file, sheet) ->
        sheet.tab = tab
        #sheet.googleId = file.id
        #sheet.fileTitle = file.title
        #sheet.sheetId = sheet.id
        #sheet.sheetTitle = sheet.title
        if sheet.selected
          $scope.deselectSheet(sheet)
        else
          sheet.selected = true
          $scope.sheetsToSave.push(sheet)


      #,-----------------------------------------------------------
      #| check and assign file and tab to already configured sheets
      #`-----------------------------------------------------------
      $scope.checkConfigured = (tab,file) ->
        configFileSheets = _.filter($scope.alreadyConfigured, (csheet) ->
          csheet.googleId == file.id
        )
        _.forEach(configFileSheets, (sheet) ->
          sheet.tab = tab
          #sheet.title = file.title
          #sheet.sheetTitle = sheet.title
          #sheet.fileTitle = file.title
          if not sheet.configured
            sheet.configured = true
            $scope.configured.push(sheet)
        )


      #,--------------------------------
      #| filtering
      #`--------------------------------
      $scope.search =
        q: ''
      $scope.filterFiles = (file)->
        if $scope.search.q == "" or !$scope.search.q
          return true
        qf = $scope.search.q.toUpperCase()
        _.str.include(file.title.toUpperCase(), qf )

      $scope.$on "refreshGdFiles", () ->
        $scope.init()

      #,--------------------------------------------------
      #| init load files from gdrive and prepare to labels
      #`--------------------------------------------------
      $scope.init = () ->
        $scope.error = null
        $scope.filesLoading = true
        $scope.gdrive =
          my:
            label:"My Drive"
            data: []
          shared:
            label:"Shared with me"
            data:[]
          bin:
            label:"Bin"
            data:[]
          allfiles:
            label:"All Spreadsheets"
            data: []
        $scope.gdriveFilesPromise().then (result) ->
          $scope.filesLoading = false
          $scope.gdrive.allfiles.data = result.items
          _.forEach($scope.gdrive.allfiles.data,(file) ->
            owner = _.find(file.owners, (owner) ->
              owner.emailAddress == $scope.ownerEmail
            )

            if file.explicitlyTrashed
              $scope.gdrive.bin.data.push(file)
              $scope.checkConfigured($scope.gdrive.bin.label, file)
            else
              if owner
                $scope.checkConfigured($scope.gdrive.my.label, file)
                $scope.gdrive.my.data.push(file)
              else
                $scope.checkConfigured($scope.gdrive.shared.label, file)
                $scope.gdrive.shared.data.push(file)
          )#end foreach
        , (err) ->
          $scope.filesLoading = false
          $scope.error = "Failed to load google drive documents"
      $scope.init()

      ]


    link: ($scope, element, attributes) ->



  ])
