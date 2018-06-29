cors      = require 'cors'
DeviceController         = require './controllers/device-controller'

class Routes
  constructor: ({@app, meshbluHttp}) ->
    @deviceController         = new DeviceController {meshbluHttp}

  register: =>
    @app.options '*', cors()
    @app.get  '/', (request, response) => response.status(200).send status: 'online'
    @app.post '/bind', @deviceController.prepare, @deviceController.update
    @app.post '/unbind', @deviceController.prepare, @deviceController.delete
    @app.post '/unbindAll', @deviceController.prepareDeleteAll, @deviceController.deleteAll
    @app.post '/register', @deviceController.registerDevices

module.exports = Routes
