express = require 'express'

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
  res.render 'index', title: 'idk'

app.get '/:loop', (req, res) ->
  res.render 'index', title: req.params.loop

app.listen 3000
