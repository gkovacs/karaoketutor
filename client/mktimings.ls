root = global ? window

root.ytplayer = null
root.videoID = null

onYouTubeIframeAPIReady = root.onYouTubeIframeAPIReady = ->
  console.log 'youtube API loaded!'
  if not root.ytplayer?
    root.ytplayer = new YT.Player('ytplayer', {
      height: '100',
      width: '640',
      videoId: root.videoID,
      #events: {
      #  'onReady': onPlayerReady,
      #  'onStateChange': onPlayerStateChange
      #}
    })

Template.mktimings.lyricLines = ->
  lines = this.lyricText.split('\n')
  return [{line: line} for line in lines]

injectScriptTag = (src, id) ->
  tag = document.createElement 'script'
  tag.src = src
  tag.id = id
  firstScriptTag = document.getElementsByTagName('script')[0]
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

Template.mktimings.invokeAfterLoad = ->
  root.videoID = this.videoID
  if root.YT? or $('#ytScriptTag').length > 0
    console.log 'already loaded'
    return ''
  injectScriptTag 'https://www.youtube.com/iframe_api', 'ytScriptTag'
  return ''