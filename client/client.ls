root = global ? window

stdgreeting = ->
  console.log 'hello?'

removePunctuation = (str) ->
  for punctuation in '[]"-+\'<>^&{}'
    str = str.split(punctuation).join(' ')
  return str

getVideoSnippet = root.getVideoSnippet = (videoID, callback) ->
  videoID = videoID.split('http://www.youtube.com/watch?v=').join('')
  Meteor.call 'getVideoSnippet', videoID, (error, result) ->
    callback(result)

getVideoTitle = root.getVideoTitle = (videoID, callback) ->
  getVideoSnippet videoID, (data) ->
    if not data?
      callback(null)
      return
    for item in data.items
      callback(item.snippet.title)
      return
    callback(null)

Template.hello.greeting = ->
  return "Welcome to karaoketutor?"

Template.hello.events {
  'click input': ->
    # template data, if any, is available in 'this'
    bootbox.alert("You pressed the button")
}

Template.videoinput.songs = ->
  searchquery = Session.get('searchsongs_query')
  if not searchquery?
    searchquery = ''
  searchregex = '.*' + searchquery + '.*'
  return Songs.find(
    {name: {$regex: searchregex, $options: 'i'} },
    {sort: {name: -1}}
  )

addNewVideo = (songurl) ->
  if !songurl? or songurl == ''
    bootbox.alert('you need to specify the song url')
    return false
  if songurl.indexOf('http://www.youtube.com/watch?v=') != 0
    bootbox.alert('the song url must start with http://www.youtube.com/watch?v=')
    return false
  songID = songurl.split('http://www.youtube.com/watch?v=').join('')
  duplicate = Songs.findOne({_id: songID})
  if duplicate?
    bootbox.alert('this video is a duplicate of ' + duplicate.name)
    return false
  getVideoTitle songurl, (songname) ->
    Songs.insert {
      name: songname,
      url: songurl,
      videoID: songID,
      _id: songID,
      time_added: new Date().getTime(),
      thumbs_up: 0,
      thumbs_down: 0,
      lyricIDs: []
    }
  return false

Template.videoinput.events {
  'click #ytinputadd': (evt) ->
    songurl = $('#ytinputurl').val().trim()
    addNewVideo(songurl)
    return false
  'keypress #ytinputurl': (evt) ->
    keycode = if evt.keyCode? then evt.keyCode else evt.which
    if keycode == 13 # enter pressed
      songurl = $('#ytinputurl').val().trim()
      addNewVideo(songurl)
      return false
  'keyup #searchsongs': (evt) ->
    Session.set('searchsongs_query', $('#searchsongs').val().trim())
}

Template.songtemplate.lyrics = ->
  return Lyrics.find {videoID: this.videoID}

Template.songtemplate.events {
  'click .addlyrics': (evt, template) ->
    #target = $(evt.currentTarget)
    songname = template.data.name
    videoID = template.data.videoID
    songurl = template.data.url
    bootbox.confirm("""
    <div style="height: 300px">
    Paste in lyrics for <a href="#{songurl}" target="_blank">#{songname}</a>
    (<a href="http://www.google.com/search?q=#{removePunctuation(songname) + ' lyrics'}" target="_blank">Search for Lyrics</a>):<br>
    <textarea style="width: 100%; height: 100%" id="songlyricsinput"></textarea>
    </div>

    """, (result) ->
      if result
        songlyrics = $('#songlyricsinput').val().trim()
        if songlyrics == ''
          return
        numLyricsForSong = template.data.lyricIDs.length
        lyricID = videoID + '_' + numLyricsForSong
        console.log lyricID
        Lyrics.insert {
          _id: lyricID,
          lyricID: lyricID,
          lyricidx: numLyricsForSong,
          videoID: videoID,
          text: songlyrics,
          timingIDs: [],
          time_added: new Date().getTime(),
          thumbs_up: 0,
          thumbs_down: 0
        }
        Songs.update({
          _id: videoID
        }, {
          $push: {
            lyricIDs: lyricID
          }
        })
    )
}

Template.lyricstemplate.preview = ->
  lines = []
  for line in this.text.split('\n')
    line = line.trim()
    if line[0 to 0] == '['
      continue
    lines.push line
  return lines.join(' ').substring(0, 40)

Template.lyricstemplate.songname = ->
  return videoNameFromID(this.videoID)

videoNameFromID = (videoID) ->
  return Songs.findOne({
    _id: videoID
  }).name

Template.lyricstemplate.events {
  'click .viewlyrics': (evt, template) ->
    lyrics = template.data.text
    lyricID = template.data.lyricID
    gameID = root.randomString(10)
    #target = $(evt.currentTarget)
    #console.log lyrics
    #console.log template
    #songname = target.attr 'songname'
    songname = videoNameFromID(template.data.videoID)
    console.log songname
    #console.log template
    bootbox.confirm("""
    #{songname}<br><br>
    <a href="/mktimings?lyricID=#{lyricID}&gameID=#{gameID}" target="_blank">Start New 2-Player Game</a><br><br>
    #{lyrics}
    """, (result) ->
      console.log result
    )
}