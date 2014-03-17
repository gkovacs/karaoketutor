root = global ? window

root.ytplayer = null
root.videoID = null
root.gameID = null
root.lyricID = null
root.numWordsTotal = 1
root.activeIndex = 0
root.prevActiveIndex = 0
root.prevprevActiveIndex = 0
root.atEndOfLine = false
root.activeLineIndex = 0
root.activePosInLine = 0
root.isVideoPlaying = false

root.gameLogs = {}

root.indexInTimingList = 0

submitTimingLogs = root.submitTimingLogs = (logs) ->
  if not logs?
    logs = root.gameLogs[root.gameID]
  TimingLogs.insert {
    lyricID: lyricID
    logs: logs
  }

playbackRecorded = root.playbackRecorded = (timingList) ->
  root.indexInTimingList = 0
  root.clientCall('', 'playVideoAtTimeForGame', [0, root.gameID])
  setInterval ->
    if root.indexInTimingList >= timingList.length
      return
    setActiveIndex(timingList[root.indexInTimingList])
    #root.clientCall('', 'setActiveIndexForGame', [timingList[root.indexInTimingList], root.gameID])
    root.indexInTimingList += 1
  , 250

scrollToView = (element) ->
  offset = element.offset().top
  if not element.is(":visible")
    element.css({"visiblity":"hidden"}).show()
    offset = element.offset().top
    element.css({"visiblity":"", "display":""})
  visible_area_start = $(window).scrollTop()
  visible_area_end = visible_area_start + window.innerHeight
  if offset < visible_area_start or offset > visible_area_end
    $('html,body').animate({scrollTop: offset - window.innerHeight/3}, 1000);
    return false;
  return true

incrementActiveIndex = ->
  idx = Session.get('activeIndex') + 1
  #idx = TimingGames.findOne({_id: root.gameID}).activeIndex + 1
  if idx >= root.numWordsTotal
    idx = root.numWordsTotal-1
  setActiveIndexAll(idx)

decrementActiveIndex = ->
  idx = Session.get('activeIndex') - 1
  #idx = TimingGames.findOne({_id: root.gameID}).activeIndex - 1
  if idx <= 0
    idx = 0
  setActiveIndexAll(idx)

setActiveIndex = root.setActiveIndex = (idx) ->
  if idx == root.activeIndex
    return false
  target = $('.lyricWord_' + idx)
  root.activeLineIndex = parseInt(target.attr('line_idx'))
  root.activePosInLine = parseInt(target.attr('pos_in_line'))
  if root.activeLineIndex != parseInt($('.lyricWord_' + (idx+1)).attr('line_idx'))
    root.atEndOfLine = true
  else
    root.atEndOfLine = false
  target.focus()
  root.prevprevActiveIndex = root.prevActiveIndex
  root.prevActiveIndex = root.activeIndex
  root.activeIndex = idx
  Session.set 'activeIndex', idx
  #TimingGames.update({_id: root.gameID}, {$set: {activeIndex: idx}})
  scrollToView(target)
  return true

setActiveIndexAll = root.setActiveIndexAll = (idx) ->
  if setActiveIndex(idx)
    if root.isVideoPlaying
      root.gameLogs[root.gameID].push {
        systemTime: new Date().getTime()
        videoTime: root.ytplayer.getCurrentTime()
        wordIdx: root.activeIndex
        wordPosInLine: root.activePosInLine
        lineIdx: root.activeLineIndex
      }
    root.clientCall('', 'setActiveIndexForGame', [idx, root.gameID])

/*
onPlayerStateChange = root.onPlayerStateChange = -> (event) ->
  console.log 'new state: ' + event.data
  if event.data == YT.PlayerState.PLAYING
    root.clientCall('', 'playVideoAtTimeForGame', [root.ytplayer.getCurrentTime(), root.gameID])
  if event.data == YT.PlayerState.PAUSED
    root.clientCall('', 'pauseVideoAtTimeForGame', [root.ytplayer.getCurrentTime(), root.gameID])
*/

Template.mktimings.events {
  'click #playPause': (evt, template) ->
    action = $('#playPause').text()
    if action == 'Play'
      #$('#playPause').text('Pause')
      #root.ytplayer.pauseVideo()
      root.clientCall('', 'playVideoAtTimeForGame', [root.ytplayer.getCurrentTime(), root.gameID])
    else
      #$('#playPause').text('Play')
      #root.ytplayer.playVideo()
      root.clientCall('', 'pauseVideoAtTimeForGame', [root.ytplayer.getCurrentTime(), root.gameID])
}

onYouTubeIframeAPIReady = root.onYouTubeIframeAPIReady = ->
  console.log 'youtube API loaded!'
  if not root.ytplayer?
    root.ytplayer = new YT.Player('ytplayer', {
      height: '100',
      width: '640',
      videoId: root.videoID,
      events: {
        onReady: ->
          root.ytplayer.playVideo()
          root.ytplayer.pauseVideo()
      }
      #events: {
      #  'onReady': onPlayerReady,
      #  'onStateChange': onPlayerStateChange
      #}
    })

injectScriptTag = (src, id) ->
  tag = document.createElement 'script'
  tag.src = src
  tag.id = id
  firstScriptTag = document.getElementsByTagName('script')[0]
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

Template.mktimings.setupBackend = ->
  #Session.set('activeIndex', 0)
  root.gameID = this.gameID
  root.lyricID = this.lyricID
  if not root.gameLogs[root.gameID]?
    root.gameLogs[root.gameID] = []
  #if not TimingGames.findOne({_id: this.gameID})?
  #  TimingGames.insert {_id: this.gameID, gameID: this.gameID, numPlayers: this.numPlayers, activeIndex: 0}
  return ''

Template.mktimings.invokeAfterLoad = ->
  root.videoID = this.videoID
  if root.YT? or $('#ytScriptTag').length > 0
    console.log 'already loaded'
    return ''
  injectScriptTag 'https://www.youtube.com/iframe_api', 'ytScriptTag'
  return ''

Template.mktimings.userID = ->
  return Session.get('userID')

Template.mktimings.lyricLines = ->
  lines = this.lyricText.split('\n')
  output = []
  global_word_idx = 0
  for line,line_idx in lines
    lineinfo = {}
    lineinfo.line = line.trim()
    lineinfo.line_idx = line_idx
    lineinfo.global_word_idx = global_word_idx
    lineinfo.words = []
    for word,word_idx in line.split(' ')
      if word.trim() == ''
        continue
      wordinfo = {}
      wordinfo.word = word
      wordinfo.pos_in_line = word_idx
      wordinfo.line_idx = line_idx
      wordinfo.global_word_idx = global_word_idx
      global_word_idx += 1
      lineinfo.words.push wordinfo
    output.push lineinfo
  root.numWordsTotal = global_word_idx
  return output

Template.wordtemplate.extraPadding = ->
  if this.pos_in_line == 0
    return 'padding-left: 10px;'
  return ''

Template.wordtemplate.isActive = ->
  #if Session.equals 'activeIndex', this.global_word_idx
  #if TimingGames.findOne({_id: root.gameID}).activeIndex == this.global_word_idx
  #if root.activeIndex == this.global_word_idx
  #console.log 'rerendering'
  if Session.equals 'activeIndex', this.global_word_idx
    return 'activeWord'
  else
    return ''

mouseoverFN = (evt, template) ->
  newidx = template.data.global_word_idx
  lineidx = template.data.line_idx
  linepos = template.data.pos_in_line
  if root.atEndOfLine
    if lineidx > root.activeLineIndex and linepos == 0 and lineidx - root.activeLineIndex < 3
      setActiveIndexAll(newidx)
      return
  #else if newidx > root.activeIndex and root.activeLineIndex == lineidx
  else
    setActiveIndexAll(newidx)

Template.wordtemplate.events {
  'click .lyricWord': (evt, template) ->
    setActiveIndexAll(template.data.global_word_idx)
  'mouseover .lyricWord': mouseoverFN
  'mouseenter .lyricWord': mouseoverFN
  'touchstart .lyricWord': (evt, template) ->
    setActiveIndexAll(template.data.global_word_idx)
}

$(document).keydown (evt) ->
  keycode = if evt.keyCode? then evt.keyCode else evt.which
  if keycode == 39 # right arrow key
    incrementActiveIndex()
    return false
  if keycode == 32 # spacebar
    incrementActiveIndex()
    return false
  if keycode == 37 # left arrow key
    decrementActiveIndex()
    return false
  console.log keycode
