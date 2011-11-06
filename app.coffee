app = require('express').createServer()
io = require('socket.io').listen(app)
dgram = require 'dgram'

#console.log(__dirname)
osc = require(__dirname + '/osc').Client
console.log(osc)

users = {}

app.listen(80);

app.get('/',
  (req, res) =>
    res.sendfile(__dirname + '/public/index.html')
)

io.sockets.on('connection',
  (socket) =>
    socket.on('setUsername', (data) =>
      console.log(data)
      username = data.username
      socket.username = username
      users[username] = username


      socket.emit('connected', {users: users})

      packet = {username: username, message: "#{username} joined", users: users}
      socket.emit('broadcast', packet)
      socket.broadcast.emit('broadcast', packet)
      #socket.broadcast.json.send({username: username, message: "#{username} joined"})
      #socket.set('username', data.username, () => socket.get('username', (err, username) => socket.emit("#{username} joined")))
    )
    #socket.emit('news', { hello: 'world' })
    socket.on('djCommand',
      (data) =>
        console.log(data)
        oscClient = new osc(6666, '10.68.69.196')
        oscClient.sendSimple('/sys/party', [data.id, data.value])
    )

    socket.on('broadcast', (data) =>
      packet = {username: socket.username, message: "Message from #{socket.username}: #{data.message}", user: users}
      socket.emit('broadcast', packet)
      socket.broadcast.emit('broadcast', packet)
    )

    socket.on('disconnect', () =>
      delete users[socket.username]
      socket.broadcast.emit('broadcast', {username: socket.username, message: "That bitch #{socket.username} left."})
    )
)
