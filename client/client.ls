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
  duplicate = Songs.findOne({_id: songurl})
  if duplicate?
    bootbox.alert('this video is a duplicate of ' + duplicate.name)
    return false
  getVideoTitle songurl, (songname) ->
    Songs.insert {
      name: songname,
      url: songurl,
      _id: songurl,
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
  return Lyrics.find {songurl: this.url}

Template.songtemplate.events {
  'click .addlyrics': (evt, template) ->
    #target = $(evt.currentTarget)
    songname = template.data.name
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
        console.log template.data.lyricIDs
        console.log template.data.lyricIDs.length
        lyricID = songurl + '_' + numLyricsForSong
        console.log lyricID
        Lyrics.insert {
          _id: lyricID,
          lyricidx: numLyricsForSong,
          songurl: songurl,
          text: songlyrics,
          timingIDs: [],
          time_added: new Date().getTime(),
          thumbs_up: 0,
          thumbs_down: 0
        }
        Songs.update({
          _id: songurl
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
  return songNameFromUrl(this.songurl)

songNameFromUrl = (songurl) ->
  return Songs.findOne({
    _id: songurl
  }).name

Template.lyricstemplate.events {
  'click .viewlyrics': (evt, template) ->
    lyrics = template.data.text
    #target = $(evt.currentTarget)
    #console.log lyrics
    #console.log template
    #songname = target.attr 'songname'
    songname = songNameFromUrl(template.data.songurl)
    console.log songname
    #console.log template
    bootbox.confirm("""
    #{songname}<br><br>
    #{lyrics}
    """, (result) ->
      console.log result
    )
}