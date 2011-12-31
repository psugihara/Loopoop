express = require 'express'
util = require 'util'
fs = require 'fs'
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
  # Allow a raw url to be passed to the loopooper.
  url = (req.param 'url') ? 'http://loopoop.s3.amazonaws.com/r2.wav'

  src = req.param 'src'
  if src?
    url = 'http://loopoop.s3.amazonaws.com/' + src

  options =
    title: src or 'Loopoop'
    audioSource: url
  res.render 'index', options

app.get '/naw', (req, res) ->
  options =
    title: 'Naw'
    msg: req.param 'msg'
  res.render 'naw', options

app.post '/upload', (req, res, next) ->
  file = req.files.upload
  if file.size > 4000000
    msg = 'Your loop has to be under 4 megabytes. Sorry.'
    return res.redirect '/naw?msg=' + msg
  if (file.type.search 'audio') == -1
    msg =  "I don't know that kind of audio file. Sorry."
    return res.redirect '/naw?msg=' + msg

  name = file.name.replace /[ \t\n]+/g, ''
  name = name.slice -20

  s3.putFile file.path, name, (err, s3res) ->
    if s3res
      res.redirect '/?src=' + name
    else
      console.log 'error'
      console.log err
    fs.unlink file.path # delete from local machine

app.listen 3000, ->
  console.log 'Express server listening on port %d in %s mode'
    , app.address().port
    , app.settings.env
