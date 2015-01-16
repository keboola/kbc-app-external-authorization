angular.module('kbc.app.External')
  .service 'Gdriveservice', [
    "kbSapiService"
    "$routeParams"
    "$q"
    "kbCsv"
    "$http"
    "$location"
    "$window"
    "$sce"
    "kbc.app.External.config"
    "$rootScope"
    (storageService, $routeParams, $q, csv,  $http, $location, $window, $sce, config, $rootScope) ->
      configBucketName = "ex-googleDrive"
      configBucketId = "sys.c-" + configBucketName
      configTableName = $location.search()["account"]#$routeParams.config
      configTableId = configBucketId + "." + configTableName
      gdriveAccount = {}
      externalLink = null

      #GOOGLE DRIVE EXTRACTOR URL:
      endpoint =  ''

      #set gdrive ex URL from given config
      angular.forEach(config.components, (component) ->
        if component.id == 'ex-google-drive'
          endpoint = component.uri
      )

      postSheetsUrl= endpoint + '/sheets'
      getFilesUrl = endpoint + '/files'
      getFileSheetsUrl = endpoint + '/sheets'
      getAuthUrl = $sce.trustAsResourceUrl(endpoint + "/oauth")
      deleteSheetUrl = endpoint + '/sheet'
      getAccountUrl = endpoint + '/account'
      generateLinkUrl = -> endpoint + "/external-link"


      sheetHeader = ["fileId","googleId","title","sheetId","sheetTitle","config"]

      http = (params) ->
        $http(params).error (data, status, headers, config) =>
          return if _.isEmpty data # load canceled usually
          $rootScope.$broadcast('storageError', data)


      #-----------------------------------
      # APPEND TOKEN TO HEADER
      #---------------------------------
      appendTokenToHeader = (params) ->
        params.headers = {} if !params.headers
        #KBC EXTERNAL AUTHORIZATION APP SPECIFIC!!!! - set token
        angular.extend params.headers,
          'X-StorageApi-Token': $location.search().token

      #-----------------------------------
      # Reset google drive account
      #---------------------------------
      resetGdriveAccount = ->
        gdriveAccount =
          email : null
          name : null
          googleId : null
          accessToken : null
          refreshToken : null


      _getFilesFromGdrive = (nextPageToken) ->
        nextpage = ""
        nextpage = "/#{nextPageToken}" if nextPageToken
        params =
          url: getFilesUrl + "/#{configTableName}" + nextpage
          method: 'GET'
        appendTokenToHeader(params)
        http(params)


      #-----------------------------------
      # PARSE ATTRIBUTES
      #---------------------------------
      parseAttributes = (attrs) ->
        _.each attrs,(attribute) ->
          switch attribute.name
            when "id"
              gdriveAccount.id = attribute.value
            when "email"
              gdriveAccount.email = attribute.value
            when "name"
              gdriveAccount.name = attribute.value
            when "googleId"
              gdriveAccount.googleId = attribute.value
            when "accessToken"
              gdriveAccount.accessToken = attribute.value
            when "refreshToken"
              gdriveAccount.refreshToken = attribute.value

      #-----------------------------------
      # PARSE ACCOUNT
      #---------------------------------
      parseAccount = (data) ->
        res = {}
        res.name = data.name
        res.id = data.id
        res.email = data.email
        res.googleName = data.googleName
        res


      getAuthUrl: () =>
        return getAuthUrl

      #-----------------------------------
      # Togge gdrive account authorization
      #------------------------------
      toogleGdriveAccountAuthorization : () ->
        params =
          url: getAuthUrl
          method: 'GET'
        appendTokenToHeader(params)
        http(params).
          success((data) ->
            #console.log data
            #console.log data['auth-url']
            $window.location= data['auth-url']

          )



      #-----------------------------------
      # Set token
      #---------------------------------
      setToken : (ptoken) ->
        sapiToken = ptoken


      #-----------------------------------
      # Set endpoint
      #---------------------------------
      setEndpoint : (pendpoint) ->
        endpoint = pendpoint

      # return external link
      externalLink : () -> externalLink


      #-----------------------------------
      # Get external link
      #---------------------------------
      getExternalLink : () ->
        deferred = $q.defer()
        params =
          url: generateLinkUrl()
          method: 'POST'
          data:
            "account": configTableName
            "referrer": "https://s3.amazonaws.com/kbc-apps.keboola.com/ex-authorize/index.html#/googledrive"
        appendTokenToHeader(params)
        $http(params)
          .success (data) ->
            externalLink = data.link
            deferred.resolve(externalLink)
          .error (err) ->
            externalLink = null
            deferred.reject(err)
        return deferred.promise


      #-----------------------------------
      # get account name
      #---------------------------------
      getAccountName : () ->
        return configTableName



      #-----------------------------------
      # Load Saved Sheets List
      #---------------------------------
      loadSavedSheetsListAndAccount : () ->
        params =
          url: getAccountUrl + "/#{configTableName}"
          method: 'GET'
        appendTokenToHeader(params)
        result = $q.defer()
        $http(params)
          .success (data) ->

            res = {}
            res.account = parseAccount(data)
            res.sheets = _.map(data.items, (item) ->
              item.config = angular.fromJson(item.config)
              item.toDelete = false
              item
              )

            result.resolve(res)
          .error (msg) ->
            result.reject([])
        return result.promise


      #-----------------------------------
      # get sheets from google drive
      #---------------------------------
      getSheetsFromGdrive : (fileId) ->
        params =
          url: getFileSheetsUrl + "/#{configTableName}/#{fileId}"
          method: 'GET'
        appendTokenToHeader(params)
        http(params)


      getFilesFromGdrivePromise: () ->
        fp = $q.defer()
        _getFilesFromGdrive().success( (result) ->
          fp.resolve(result)
        )
        .error( (err) ->
          fp.reject(err)
        )
        fp



      #-----------------------------------
      # get files from google drive
      #---------------------------------
      getFilesFromGdrive : (nextPageToken) ->
        _getFilesFromGdrive(nextPageToken)

      #-----------------------------------
      # Retrieve gdrive account from SAPIs
      #---------------------------------
      retrieveGdriveAccount : ->
        result = $q.defer()
        resetGdriveAccount()
        storageService
          .getTable(configTableId)
          .success (data) ->
            parseAttributes(data.attributes)
            if gdriveAccount.name and gdriveAccount.email and gdriveAccount.googleId and gdriveAccount.refreshToken and gdriveAccount.accessToken

              result.resolve(gdriveAccount)
            else
              result.resolve(null)
          .error () ->
            result.reject({})
        result.promise


      #-----------------------------------
      # Store new sheets
      #-------------------------------
      storeNewSheets: (newSheets)  ->
        params=
          url: postSheetsUrl + "/#{configTableName}"
          data:
            data:
              newSheets
          method: 'POST'
        appendTokenToHeader(params)

        http(params)

      #-----------------------------------
      # Delete sheets
      #--------------------------------
      deleteSheet: (sheetsToDelete) ->
        params=
          url: deleteSheetUrl + "/#{configTableName}/#{sheetsToDelete.fileId}/#{sheetsToDelete.sheetId}"
          method: 'DELETE'
        appendTokenToHeader(params)
        http(params)


      #-----------------------------------
      # Store new sheets
      #--------------------------------
      storeSheets: (newSheets) ->
        result = $q.defer()
        newSheets = _.map(newSheets, (item) ->
          item.config = angular.toJson(item.config)
          item
        )
        tabledata = csv.create([sheetHeader].concat(newSheets))
        storageService
          .saveTableData(configTableId, tabledata, {})
          .success ()  ->
            result.resolve("ok")
          .error (msg) ->
            result.reject(msg)
        return result.promise

    # AngularJS will instantiate a singleton by calling "new" on this function
  ]
