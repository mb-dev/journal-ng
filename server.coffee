express = require 'express' 

exports.app = app = express()
app.use(express.favicon())
app.use(express.static(__dirname + '/public'))

app.get '/css/*', (req, res) -> res.send(404, 'Not found')
app.get '/images/*', (req, res) -> res.send(404, 'Not found')
app.get '/fonts/*', (req, res) -> res.send(404, 'Not found')
app.get '/js/*', (req, res) -> res.send(404, 'Not found')
app.get '/partials/*', (req, res) -> res.send(404, 'Not found')
app.get '/*', (req, res) -> res.sendfile('public/index.html')

if process.env.NODE_ENV == 'development'
  app.listen 4000, "0.0.0.0"
else
  app.listen 4000
