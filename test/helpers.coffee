
###
Bootstrap app module for test purposes
Expected for use in beforeEach jasmine test method
###
window.appModule = ->
    module('kbc.app.External', ($provide) ->
      $provide.constant('kbc.app.External.config',
        sapi:
          token:
            token: ''
          endpoint: ''
        basePath: '/'
        components: [{"id":"gooddata-writer","uri":"https:\/\/syrup.keboola.com\/gooddata-writer"},{"id":"transformation","uri":"https:\/\/transformation.keboola.com"},{"id":"provisioning","uri":"https:\/\/provisioning.keboola.com\/provisioning"},{"id":"orchestrator-2","uri":"https:\/\/orchestrator-2.keboola.com"}]
      )
    )