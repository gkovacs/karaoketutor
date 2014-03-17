root = global ? window

Songs = root.Songs = new Meteor.Collection("songs")
Lyrics = root.Lyrics = new Meteor.Collection("lyrics")
YoutubeSnippets = root.YoutubeSnippets = new Meteor.Collection("ytsnippets")

Router.configure {
  layoutTemplate: 'layout'
}

getLyricInfoSafe = root.getLyricInfoSafe = (lyricID) ->
  try
    if not lyricID? or lyricID == ''
      return null
    return getLyricInfo(lyricID)
  catch error
    return null

getLyricInfo = root.getLyricInfo = (lyricID) ->
  lyricDoc = Lyrics.findOne {_id: lyricID}
  lyricText = lyricDoc.text
  videoID = lyricDoc.videoID
  videoDoc = Songs.findOne {_id: videoID}
  url = videoDoc.url
  name = videoDoc.name
  return {
    lyricID: lyricID,
    videoID: videoID,
    url: url,
    name: name,
    lyricText: lyricText
  }

Router.map ->
  this.route 'home', {
    path: '/',
    template: 'home'
  }
  this.route 'playlyrics', {
    path: '/playlyrics',
    template: 'playlyrics',
    notFoundTemplate: 'loading',
    data: ->
      return getLyricInfoSafe(this.params.lyricID)
  }
  this.route 'mktimings', {
    path: '/mktimings',
    template: 'mktimings',
    notFoundTemplate: 'loading',
    data: ->
      return getLyricInfoSafe(this.params.lyricID)
  }

