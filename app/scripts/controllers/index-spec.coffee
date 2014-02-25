describe 'Controller: IndexController', () ->

  beforeEach appModule()

  IndexController = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    IndexController = $controller 'IndexController', {
      $scope: scope
    }

  it 'should attach buckets to scope', ->
    expect(scope.buckets).toBeDefined()



