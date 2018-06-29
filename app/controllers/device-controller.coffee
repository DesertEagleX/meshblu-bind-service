debug = require('debug')('meshblu-device-binder:device-controller')
_ = require 'lodash'
validator = require 'validator'
url = require 'url'
path = require('path')
fs = require 'fs'

class DeviceController
  constructor: ({@meshbluHttp}) ->

  prepare: (request, response, next) =>
    {userUuid, deviceUuid} = request.body
    debug "userUuid,deviceUuid: ", userUuid,deviceUuid
    return response.status(422).send Error: 'userUuid required' if _.isEmpty(userUuid)
    return response.status(422).send Error: 'deviceUuid required' if _.isEmpty(deviceUuid)

    request.userUuid = userUuid
    request.deviceUuid = deviceUuid
    @addAuth userUuid, (error, foundDevice)=>
      debug 'user device find error', error if error?
      return response.status(404).send Error: 'device not found' unless foundDevice
      @addAuth deviceUuid, (error, foundDevice)=>
        debug 'device find error', error if error?
        return response.status(404).send Error: 'device not found' unless foundDevice
        next()
 
  prepareDeleteAll: (request, response, next) =>
    userUuid = request.body.userUuid
    debug "userUuid,deviceUuid: ", userUuid
    return response.status(422).send Error: 'userUuid required' if _.isEmpty(userUuid)

    request.userUuid = userUuid
    @addAuth userUuid, (error, foundDevice)=>
      debug 'user device find error', error if error?
      return response.status(404).send Error: 'device not found user device' unless foundDevice
      next() 

  addAuth: (uuid, callback) =>
    @meshbluHttp.devices uuid: uuid, (error, devices) =>
      debug 'device', devices
      return callback error if error?
      return callback null, ! _.isEmpty devices

  registerDevices: (request, response) =>
    num = request.body.num
    @i_count = 501
    return response.status(422).send Error: 'number required' if _.isEmpty(num)
    console.log num
    for i in [0..num-1]
      console.log "register#{i}"
      @meshbluHttp.register {type: 'device:yeelight'}, (error, res)=>
        root = './app/uuid_and_token/'
        pathName = @i_count + '.txt'
        filePath = path.join(root,pathName)
        option = res.uuid + ' '+ res.token
        console.log option,@i_count,root,pathName,filePath
        fs.writeFileSync filePath,option
        @i_count++
    return response.status(200).send Info: 'register success'

  update: (request, response) =>
    {userUuid, deviceUuid} = request
    return response.status(422).send Error: 'userUuid required' if _.isEmpty(userUuid)
    return response.status(422).send Error: 'deviceUuid required' if _.isEmpty(deviceUuid)

    userOptions = {"$addToSet":{
      "discoverWhitelist": {"$each": [deviceUuid]},
      "configureWhitelist": {"$each": [deviceUuid]},
      "sendWhitelist": {"$each": [deviceUuid]},
      "receiveWhitelist": {"$each": [deviceUuid]}
      }
    }

    deviceOptions = {"$addToSet":{
      "discoverWhitelist": {"$each": [userUuid]},
      "configureWhitelist": {"$each": [userUuid]},
      "sendWhitelist": {"$each": [userUuid]},
      "receiveWhitelist": {"$each": [userUuid]}
      }
    }
      

    @meshbluHttp.updateDangerously userUuid, userOptions, (error, res)=>
      if(error)
        return response.status(500).send Error: 'Update error'
      else
        @meshbluHttp.updateDangerously deviceUuid, deviceOptions, (error, res)=>
          if(error)
            return response.status(500).send Error: 'Update error'
          else
            return response.status(200).send Info: 'bind success'

  delete: (request, response) =>
    {userUuid, deviceUuid} = request
    return response.status(422).send Error: 'userUuid required' if _.isEmpty(userUuid)
    return response.status(422).send Error: 'deviceUuid required' if _.isEmpty(deviceUuid)

    userOptions = {"$pull":{
      "discoverWhitelist": {"$in": [deviceUuid]},
      "configureWhitelist": {"$in": [deviceUuid]},
      "sendWhitelist": {"$in": [deviceUuid]},
      "receiveWhitelist": {"$in": [deviceUuid]}
      }
    }

    deviceOptions = {"$pull":{
      "discoverWhitelist": {"$in": [userUuid]},
      "configureWhitelist": {"$in": [userUuid]},
      "sendWhitelist": {"$in": [userUuid]},
      "receiveWhitelist": {"$in": [userUuid]}
      }
    }
      

    @meshbluHttp.updateDangerously userUuid, userOptions, (error, res)=>
      if(error)
        return response.status(500).send Error: 'Update error'
      else
        @meshbluHttp.updateDangerously deviceUuid, deviceOptions, (error, res)=>
          if(error)
            return response.status(500).send Error: 'Update error'
          else
            return response.status(200).send Info: 'unbind success'

  deleteAll:(request, response) =>
    userUuid = request.body.userUuid
    return response.status(422).send Error: 'userUuid required' if _.isEmpty(userUuid)

    @authUuid = @meshbluHttp.uuid
    @countDone = 0
    @devicesToDelete = []
    @meshbluHttp.device  userUuid,(error, res)=>
      @devicesToDelete = res.discoverWhitelist
      @length = @devicesToDelete.length
      if @length == 1 and @devicesToDelete[0]== @authUuid
        return response.status(200).send Info: 'unbind success'
      for i in [0..@devicesToDelete.length-1]
        if @devicesToDelete[i] != @authUuid
          deviceUuid = @devicesToDelete[i]
          @_setdownAll(userUuid,deviceUuid, response)

  _setdownAll: (userUuid,deviceUuid, response)=>

    userOptions = {"$pull":{
      "discoverWhitelist": {"$in": [deviceUuid]},
      "configureWhitelist": {"$in": [deviceUuid]},
      "sendWhitelist": {"$in": [deviceUuid]},
      "receiveWhitelist": {"$in": [deviceUuid]}
      }
    }

    deviceOptions = {"$pull":{
      "discoverWhitelist": {"$in": [userUuid]},
      "configureWhitelist": {"$in": [userUuid]},
      "sendWhitelist": {"$in": [userUuid]},
      "receiveWhitelist": {"$in": [userUuid]}
      }
    }
      

    @meshbluHttp.updateDangerously userUuid, userOptions, (error, res)=>
      if(error)
        return response.status(500).send Error: 'Update error'
      else
        @meshbluHttp.updateDangerously deviceUuid, deviceOptions, (error, res)=>
          if(error)
            return response.status(500).send Error: 'Update error'
          else
            @countDone++
            if @countDone == @length or @countDone == @length-1
              return response.status(200).send Info: 'unbind all devices success'

module.exports = DeviceController
