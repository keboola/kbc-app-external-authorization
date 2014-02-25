###
  Mockup bootstrap
###

jQuery(($) ->
  appName = 'kbc.app.External'
  sapiUrl = 'https://connection.keboola.com'

  getParameterByName = (name) ->
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
    results = regex.exec(location.search)
    (if not results? then "" else decodeURIComponent(results[1].replace(/\+/g, " ")))

  startApp = (configuration) ->
    # create configuration
    angular.module(appName)
    .constant("#{appName}.config",
        sapi:
          token:
            token: getParameterByName('token')
          endpoint: sapiUrl
        basePath: '/'
        appName: appName
        components: configuration.components
      )

    angular.bootstrap(angular.element.find('body'), [appName])

  $.get("#{sapiUrl}/v2/storage").success(startApp)
)

