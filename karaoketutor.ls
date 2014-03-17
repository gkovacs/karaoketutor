root = global ? window

Songs = root.Songs = new Meteor.Collection("songs")
Lyrics = root.Lyrics = new Meteor.Collection("lyrics")
YoutubeSnippets = root.YoutubeSnippets = new Meteor.Collection("ytsnippets")
TimingGames = root.TimingGames = new Meteor.Collection("timinggames")
TimingLogs = root.TimingLogs = new Meteor.Collection("timinglogs")

Router.configure {
  layoutTemplate: 'layout'
}

getLyricInfoSafe = root.getLyricInfoSafe = (lyricID) ->
  try
    if not lyricID? or lyricID == ''
      return null
    return getLyricInfo(lyricID, gameID)
  catch error
    return null

pickRandom = (lst) ->
  idx = Math.floor(Math.random()*lst.length)
  return lst[idx]

randomString = root.randomString = (length) ->
  output = []
  available = ['a' to 'z'].concat ['0' to '9']
  for i in [0 til length]
    output.push pickRandom(available)
  return output.join('')

getLyricInfo = root.getLyricInfo = (lyricID) ->
  lyricDoc = Lyrics.findOne {_id: lyricID}
  lyricText = lyricDoc.text
  videoID = lyricDoc.videoID
  videoDoc = Songs.findOne {_id: videoID}
  url = videoDoc.url
  name = videoDoc.name
  if not gameID?
    gameID = randomString(10)
  return {
    lyricID: lyricID,
    videoID: videoID,
    url: url,
    name: name,
    lyricText: lyricText
  }

Router.map ->
  this.route 'home', {
    path: '/'
    template: 'home'
    #onAfterRun: ->
    #  document.title = 'Karaoke Tutor'
  }
  this.route 'playlyrics', {
    path: '/playlyrics'
    template: 'playlyrics'
    notFoundTemplate: 'loading'
    data: ->
      return getLyricInfoSafe(this.params.lyricID, this.params.gameID)
  }
  this.route 'mktimings', {
    path: '/mktimings'
    template: 'mktimings'
    notFoundTemplate: 'loading'
    data: ->
      lyricsInfo = getLyricInfoSafe(this.params.lyricID)
      if not lyricsInfo? or not this.params.gameID?
        return null
      lyricsInfo.gameID = this.params.gameID
      lyricsInfo.numPlayers = if this.params.numPlayers? then parseInt(this.params.numPlayers) else 2
      return lyricsInfo
    #onAfterRun: ->
    #  document.title = 'Karaoke Tutor'
  }


if Meteor.isClient
  userID = $.cookie('userID')
  if not userID? or userID == ''
    userID = randomString(10)
    $.cookie('userID', userID)
  Session.set('userID', userID)
  root.userID = userID
  Meteor.ClientCall.setClientId(userID)

  Meteor.ClientCall.methods {
    setActiveIndex: (idx) ->
      console.log 'new active index is: ' + idx
      root.setActiveIndex(idx)
    setActiveIndexForGame: (idx, gameID) ->
      if root.gameID == gameID
        root.setActiveIndex(idx)
    playVideoAtTimeForGame: (time, gameID) ->
      if root.gameID == gameID and root.ytplayer?
        root.isVideoPlaying = true
        $('#playPause').text('Pause')
        root.ytplayer.seekTo(time)
        root.ytplayer.playVideo()
    pauseVideoAtTimeForGame: (time, gameID) ->
      if root.gameID == gameID and root.ytplayer?
        root.isVideoPlaying = false
        $('#playPause').text('Play')
        root.ytplayer.pauseVideo()
        root.ytplayer.seekTo(time)
  }

  root.clientCall = (clientId, method, args, callback) ->
    # strangely this is resulting in all clients getting called, regardless of the clientId specified...
    Meteor.call('clientCall', clientId, method, args, callback)
