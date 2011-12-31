express = require 'express'
util = require 'util'
secrets = require './secrets.js'
s3 = require('knox').createClient
  key: secrets.accessKeyId
  secret: secrets.secretAccessKey
  bucket: 'loopoop'

app = express.createServer()

app.configure ->
    app.use express.methodOverride()
    app.use express.bodyParser()
    app.use app.router
    app.set 'views', __dirname + '/views'
    app.set 'view engine', 'jade'

app.configure 'development', ->
    app.use express.static(__dirname + '/public')
    app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure 'production', ->
  oneYear = 31557600000
  app.use express.static(__dirname + '/public', { maxAge: oneYear })
  app.use express.errorHandler()


# ROUTES
app.get '/', (req, res) ->
  src = req.param 'src'
  options =
    title: src or 'Loopoop'
    audioSource: src or 'http://loopoop.s3.amazonaws.com/r2.wav'
  res.render 'index', options

app.post '/upload', (req, res, next) ->
  file = req.files.upload
  name = file.name.replace /[ \t\n]+/g, ''
  name = name.slice name.length-20, name.length
  s3.putFile file.path, name, (err, s3res) ->
    if s3res
      res.redirect '/?src=' + s3res.client._httpMessage.url
    else
      console.log 'error'
      console.log err

app.listen 3000, ->
  console.log 'Express server listening on port %d in %s mode'
    , app.address().port
    , app.settings.env
