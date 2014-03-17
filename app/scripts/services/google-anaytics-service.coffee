
angular.module('kbc.app.External')
  .service 'Googleanayticsservice', [
    "$routeParams"
    "$http"
    "$location"
    "$q"
    ($routeParams, $http, $location, $q) ->
      # AngularJS will instantiate a singleton by calling "new" on this function
      configBucketName = "ex-googleAnalytics"
      configBucketId = "sys.c-" + configBucketName
      configTableName = $routeParams.account
      configTableId = configBucketId + "." + configTableName
      profiles = null
      queries = null
      
      defaultEndpoint = 'https://syrup.keboola.com/ex-google-analytics'
      
      
      externalLink = null
      sapiToken = ''
      endpoint = defaultEndpoint

      postAuthUrl =     -> endpoint + "/oauth"
      getProfilesUrl =  -> endpoint + "/profiles"
      postProfilesUrl=  -> endpoint + "/profiles"
      getAccountUrl =   ->  endpoint + "/account"
      postAccountUrl =  -> endpoint + "/account"
      generateLinkUrl = -> endpoint + "/external-link"

      #-----------------------------------
      # Append token header to params
      #---------------------------------
      appendTokenToHeader = (params) ->
        params.headers = {} if !params.headers
        angular.extend params.headers,
          'X-StorageApi-Token': $routeParams.token #storageService.apiToken
      
      
      #-----------------------------------
      # POST ACCOUNT
      #---------------------------------
      postAccount= (queriesToSave) ->
        config =
          configuration:queriesToSave
        params =
          data:config
          method: 'POST'
          url: postAccountUrl() + "/#{configTableName}"
        appendTokenToHeader(params)
        $http(params)
      
      
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
        
      useDevelEndpoint : () ->
        endpoint = develEndpoint
        
      #-----------------------------------
      # Get external link
      #---------------------------------
      getExternalLink : ( ) ->
        deferred = $q.defer()
        
        params =
          url: generateLinkUrl()
          method: 'POST'
          data:
            "account": configTableName
            "referrer": "TODO!"
            
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
      # Get all profiles
      #---------------------------------
      getAllProfiles: () ->
        if profiles
         return profiles
        loadQueriesAndSavedProfiles().then( (data) ->
          return data.profiles
        ,() ->
          return null
        )
      
      #-----------------------------------
      # Query Name Exists
      #---------------------------------
      queryNameExists: ( nameParam) ->
        result = false
        _.forEach( queries, (val,key) ->
          
          if key == nameParam
            result = true
        )
        result
          
      
      #-----------------------------------
      # SAVE CONFIGURATION
      #---------------------------------
      #originalName - is the former name of the config - useful if editing the config
      saveConfiguration : (configName, originalName, data) ->
        configItem =
          'metrics':data.metrics ? []
          'dimensions':data.dimensions ? []
        
        if data.filters and data.filters[0] and data.filters[0] != ''
          filters = data.filters[0].replace /ga:/g,''
          configItem.filters = [filters]
              
        if data.profile and data.profile !=''
          configItem.profile = data.profile
          
        isNew = originalName == ''
        #now we filter out the old config
        if not isNew
          newQueries = _.omit( queries, originalName)
          newQueries[configName] = configItem
        else
          newQueries = _.clone(queries)
          newConfig = {}
          newConfig[configName] = configItem
          newQueries= _.extend(newQueries, newConfig)
        postAccount(newQueries)
      
      
      #-----------------------------------
      # LOAD queries and savedprofiles
      #---------------------------------
      removeConfig: (queryName) ->
        newQueries = _.omit( queries, queryName)
        postAccount(newQueries)
      
      #-----------------------------------
      # LOAD queries and savedprofiles
      #---------------------------------
      loadQueriesAndSavedProfiles : ->
        params =
          url: getAccountUrl() + "/#{configTableName}"
          method: 'GET'
        appendTokenToHeader(params)
        def = $q.defer()
        $http(params)
          .success (data) ->
            profiles = data.items
            queries = data.configuration
            if not queries or queries is [] or queries.length == 0
              queries = {}
            result =
              'profiles':profiles
              'queries':queries
              'googleName': data.googleName
              'email': data.email
            def.resolve(result)
          .error () ->
            def.reject("error")
        return def.promise
        
            
      #-----------------------------------
      # getConfigName
      #---------------------------------
      getConfigName : ->
        return configTableName
      
      
      #-----------------------------------
      # getEndpointUrl
      #---------------------------------
      getEndpointUrl : ->
        return endpoint
      
      #-----------------------------------
      # getAuthUrl
      #---------------------------------
      getAuthUrl: ->
        return postAuthUrl()
      
      
      #-----------------------------------
      # go to URLs
      #---------------------------------
      goToIndex: () ->
        $location.url('/?config='+configTableName)
        
      goToProfiles: () ->
        $location.url('/profiles?config='+configTableName)
      
      #-----------------------------------
      # POST PROFILES
      #---------------------------------
      postProfiles: (profiles) ->
        params =
          data: profiles
          url: postProfilesUrl() + "/#{configTableName}"
          method: 'POST'
        appendTokenToHeader(params)
        $http(params)
      
      #-----------------------------------
      # GET PROFILES
      #---------------------------------
      getProfiles: () ->
        params =
          url: getProfilesUrl() + "/#{configTableName}"
          method: 'GET'
        appendTokenToHeader(params)
        $http(params)
  ]