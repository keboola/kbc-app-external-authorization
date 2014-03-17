### configuration defaults
  In dev mode injected by bootstrap.coffee script
  I
  n production deployed into kbc provided by kbc
###
angular
.module('kbc.app.External.config', [])
.constant('kbc.app.External.config',
  appName: 'kbc.app.External'
  appVersion: 'v1'
  templatesBasePath: '/app'
  token: {} # token object
  components: [] # list of kbc components provided by https://connection.keboola.com/v2/storage
)

angular
.module('kbc.app.External', [
  # ng modules
  
  'ngResource'
  'ngSanitize'
  'ngRoute'

  # demo application modules
  'kbc.app.External.config'

  # keboola common library
  'kb'
  'kb.accordion'
  'kb.i18n'

  # error handling
  'kb.exceptionHandler'

  # third party library modules
  'ui.bootstrap'
])
.config([
  '$routeProvider'
  '$locationProvider'
  '$tooltipProvider'
  'kbAppVersionProvider'
  'kbc.app.External.config'
  ($routeProvider, $locationProvider, $tooltipProvider, appVersionProvider, config) ->
    appVersionProvider
    .setVersion(config.appVersion)
    .setBasePath(config.basePath)

    $tooltipProvider.options(
      appendToBody: true
    )

    $routeProvider
    .when('/',
        templateUrl: "views/pages/index.html"
        controller: 'IndexController'
      )
    .when('/googledrive',
        templateUrl: "views/pages/add-new-sheet.html"
        controller: 'AddsheetController'
      )
    .when('/googleanalytics',
        templateUrl: "views/pages/add-profiles.html"
        controller: 'AddProfilesController'
      )
    .otherwise(
        redirectTo: '/'
      )

    $locationProvider.html5Mode(false)
])

# initialization
.run([
  '$rootScope'
  'kbSapiErrorHandler'
  'kbSapiService'
  'kbAppVersion'
  'kbc.app.External.config'
  ($rootScope, storageErrorHandler, storageService, appVersion, appConfig) ->
    getComponentConfig = (id) ->
      component = _.find(appConfig.components, (component) ->
        component.id == id
      )
      throw new Error("Component #{id} not found") if !component
      component

    # wire storage error handler - trigger error modal on error
    $rootScope.$on('storageError', (event, errorResponse) ->
      storageErrorHandler.handleError(errorResponse)
    )

    # set tokens and urls for SAPI and TAPI
    storageService.setVerifiedToken(appConfig.sapi.token)
    storageService.endpoint = appConfig.sapi.endpoint

    # put configs to rootScope to be simple accesible in all views and controllers
    $rootScope.appVersion = appVersion
    $rootScope.appConfig = appConfig

])

