app = require('express').createServer()
io = require('socket.io').listen(app)
dgram = require 'dgram'

#console.log(__dirname)
osc = require(__dirname + '/osc').Client


users = {}
playQueue = []
currentTrack = {isPlaying: false}


# rdio config
#OAuth = require('oauth').OAuth
#rdio = require('rdio')({rdio_api_key: 'xap5xzbtdek3zvb54ggb9wna', rdio_api_shared: '94QPfmkruy', callback_url: "10.68.68.24/oauth/callback"})

#rdioSession =  {}


#rdio.getRequestToken((error, oauth_token, oauth_token_secret, results) =>
#  if(error) {
#    throw new Error(error)
#  else
    #store the tokens in the session
#    rdioSession.oauth_token = oauth_token
#    rdioSession.oauth_token_secret = oauth_token_secret

    #redirect the user to authorize the token
#    res.redirect(ct.config.rdio_oauth_auth+oauth_token);
#)

app.listen(80);

app.get('/',
  (req, res) =>
    res.sendfile(__dirname + '/public/index.html')
)

io.sockets.on('connection',
  (socket) =>

    sendSong = (track) ->
      currentTrack.track = track
      currentTrack.isPlaying = true
      nextSongIn = track.length*1000
      console.log "Next song in #{nextSongIn}"
      currentTrack.timeoutId = setTimeout(clearSong, nextSongIn)
      oscClient = new osc(6666, '10.68.69.196')
      packet = ['song', track.href] #, data.name, data.artists[0].name]
      oscClient.sendSimple('/sys/party', packet)
      console.log "Sending song to osc:", packet
      playlistPacket = {currentTrack: track, playlist: playQueue}
      socket.broadcast.emit('playlist', playlistPacket)
      socket.emit('playlist', playlistPacket)


    clearSong = () ->
      console.log('clearing song')
      if currentTrack.timetouId && currentTrack.timeoutId > 0
        clearTimeout(currentTrack.timeoutId)
        currentTrack.timeoutId = 0

      currentTrack.isPlaying = false
      nextSong()


    nextSong = () ->
      if playQueue.length == 0
        return

      if currentTrack.isPlaying
        console.log('nextSong: song is already playing...')
        return
      else
        console.log('nexting song')
        track = playQueue.shift()
        sendSong track

    queueSong = (track) ->
      playQueue.push(track)

      # nothing is playing
      if currentTrack.track
        playlistPacket = {currentTrack: currentTrack.track, playlist: playQueue}
        socket.broadcast.emit('playlist', playlistPacket)
        socket.emit('playlist', playlistPacket)

      console.log "Queueing song #{track.name}", (t.name for t in playQueue)
      nextSong()


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
        #socket.emit('broadcast', {foo:'bar'})

    )

    socket.on('play',
      (data) =>
        if data == null
          return

        console.log(data)

        if data.href && data.name && data.artists[0].name
          track = {href:data.href, name:data.name, length:data.length, artist:data.artists[0].name}
          queueSong(track)
        try
          console.log
        catch error
          console.log 'Play Error!', error
    )

    socket.on('playlist', (data) =>
      packet = {playlist: playQueue, currentTrack: currentTrack.track}
      socket.emit('playlist', packet)
    )

    socket.on('skip', (data) =>
      clearSong()
    )

    socket.on('broadcast', (data) =>
      packet = {username: socket.username, message: "Message from #{socket.username}: #{data.message}", user: users}
      socket.emit('broadcast', packet)
      socket.broadcast.emit('broadcast', packet)
    )

    socket.on('disconnect', () =>
      delete users[socket.username]
      #socket.broadcast.emit('broadcast', {username: socket.username, message: "That bitch #{socket.username} left."})
    )
)
