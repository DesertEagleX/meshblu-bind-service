express            = require 'express'
morgan             = require 'morgan'
bodyParser         = require 'body-parser'
cors               = require 'cors'
MeshbluHttp        = require 'meshblu-http'
OctobluRaven       = require 'octoblu-raven'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
packageVersion     = require 'express-package-version'
sendError          = require 'express-send-error'
Routes             = require './app/routes'
fs                 = require 'fs'

meshbluJSONPath = './meshblu.json'
if !fs.existsSync(meshbluJSONPath)
  #fs.writeFileSync '/data/meshblu-bind-service/meshblu.json', fs.readFileSync('/data/meshblu-authenticator-email-password-2.0.13/meshblu.json') 
  console.log "require meshblu.json"
try
  meshbluJSON  = require './meshblu.json'
catch
  meshbluJSON =
    uuid:   process.env.EMAIL_PASSWORD_AUTHENTICATOR_UUID
    token:  process.env.EMAIL_PASSWORD_AUTHENTICATOR_TOKEN
    server: process.env.MESHBLU_HOST
    port:   process.env.MESHBLU_PORT

meshbluJSON.name = process.env.EMAIL_PASSWORD_AUTHENTICATOR_NAME ? 'bind service'

port = process.env.EMAIL_PASSWORD_AUTHENTICATOR_PORT ? process.env.PORT ? 3005

octobluRaven = new OctobluRaven()
octobluRaven.patchGlobal()

app = express()
app.use octobluRaven.express().handleErrors()
app.use sendError()
app.use cors()

app.use meshbluHealthcheck()
app.use packageVersion()

app.use morgan 'dev', immediate: false unless @disableLogging
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cors()

meshbluHttp = new MeshbluHttp meshbluJSON

authenticatorUuid = meshbluJSON.uuid
authenticatorName = meshbluJSON.name

meshbluHttp.device meshbluJSON.uuid, (error, device) ->
  if error?
    console.error error.message, error.stack
    process.exit 1

  app.listen port, =>
    console.log "listening at localhost:#{port}"

routes = new Routes {app, meshbluHttp}
routes.register()


process.on 'SIGTERM', =>
  console.log 'SIGTERM caught, exiting'
  process.exit 0
