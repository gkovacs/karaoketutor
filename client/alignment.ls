root = global ? window

if not prelude?
  if root.prelude?
    prelude = root.prelude
  else
    prelude = require \prelude-ls

FRACSEC = 4

logsToTimeListHoldMulti = root.logsToTimeListHoldMulti = (logsList) ->
  maxVideoTime = prelude.maximum [prelude.maximum([videoTime for {videoTime} in logs]) for logs in logsList]
  maxTime = Math.round(maxVideoTime*FRACSEC)
  maxIdx = prelude.maximum [prelude.maximum([wordIdx for {wordIdx} in logs]) for logs in logsList]
  output = []
  for time in [0 to maxTime]
    output.push [0]*(maxIdx+1)
  for logs in logsList
    sortedLogs = prelude.sort-by (.videoTime), logs
    for idx in [0 til sortedLogs.length]
      {wordIdx,videoTime} = sortedLogs[idx]
      startTime = Math.round(videoTime*FRACSEC)
      nextIntervalData = sortedLogs[idx+1]
      if nextIntervalData?
        nextTime = nextIntervalData.videoTime * FRACSEC |> Math.round
      else
        nextTime = maxTime+1
      for time in [startTime til nextTime]
        output[time][wordIdx] += 1
  return output

logsToTimeListHold = root.logsToTimeListHold = (logs) ->
  maxVideoTime = prelude.maximum [videoTime for {videoTime} in logs]
  maxTime = Math.round(maxVideoTime*FRACSEC)
  maxIdx = prelude.maximum [wordIdx for {wordIdx} in logs]
  output = []
  for time in [0 to maxTime]
    output.push [0]*(maxIdx+1)
  sortedLogs = prelude.sort-by (.videoTime), logs
  for idx in [0 til sortedLogs.length]
    {wordIdx,videoTime} = sortedLogs[idx]
    startTime = Math.round(videoTime*FRACSEC)
    nextIntervalData = sortedLogs[idx+1]
    if nextIntervalData?
      nextTime = nextIntervalData.videoTime * FRACSEC |> Math.round
    else
      nextTime = maxTime+1
    for time in [startTime til nextTime]
      output[time][wordIdx] += 1
  return output

logsToTimeList = root.logsToTimeList = (logs) ->
  maxTime = prelude.maximum [Math.round(videoTime*FRACSEC) for {videoTime} in logs]
  maxIdx = prelude.maximum [wordIdx for {wordIdx} in logs]
  output = []
  for time in [0 to maxTime]
    output.push [0]*(maxIdx+1)
  for {wordIdx,videoTime} in logs
    time = Math.round(videoTime*FRACSEC)
    output[time][wordIdx] += 1
  return output

compute_time_word_path = root.compute_time_word_path = (time_to_gwordnum_count) ->
  DP = [] # scores at time -> gwordnum
  backptr_wordtrans = [] # 1 if we got there by word transition, 0 otherwise
  for time,gwordnum_count of time_to_gwordnum_count
    DP[time] = []
    backptr_wordtrans[time] = []
    for gwordnum in [0 to Math.min(time, gwordnum_count.length-1)]
      DP[time].push(0)
      backptr_wordtrans[time].push(0)
  for gwordnum_count,time in time_to_gwordnum_count
    if time == 0
      DP[0][0] = time_to_gwordnum_count[0][0]
      continue
    for gwordnum in [0 to Math.min(time, gwordnum_count.length-1)]
      wordtransition_score = -1
      if gwordnum > 0
        wordtransition_score = DP[time-1][gwordnum-1] + time_to_gwordnum_count[time][gwordnum]
      wordstay_score = -1
      if DP[time-1]? and DP[time-1][gwordnum]?
        wordstay_score = DP[time-1][gwordnum] + time_to_gwordnum_count[time][gwordnum]
      if wordtransition_score > wordstay_score
        backptr_wordtrans[time][gwordnum] = 1
        DP[time][gwordnum] = wordtransition_score
      else
        DP[time][gwordnum] = wordstay_score
  time_to_word = []
  last_row = backptr_wordtrans[backptr_wordtrans.length-1]
  word_idx = last_row.length - 1
  for i in [backptr_wordtrans.length-1 to 0 by -1]
    is_wordtrans = backptr_wordtrans[i][word_idx]
    time_to_word.push(word_idx)
    if is_wordtrans
      word_idx -= 1
  time_to_word.reverse()
  return time_to_word


main = ->
  #console.log prelude.maximum([3,6,8])
  #logs = [{"systemTime":1395090166237,"videoTime":0.931924,"wordIdx":0,"wordPosInLine":0,"lineIdx":0},{"systemTime":1395090166782,"videoTime":1.709568,"wordIdx":1,"wordPosInLine":1,"lineIdx":0},{"systemTime":1395090167181,"videoTime":1.961337,"wordIdx":2,"wordPosInLine":0,"lineIdx":2},{"systemTime":1395090167663,"videoTime":2.464566,"wordIdx":3,"wordPosInLine":1,"lineIdx":2},{"systemTime":1395090168027,"videoTime":2.715855,"wordIdx":4,"wordPosInLine":0,"lineIdx":3},{"systemTime":1395090168406,"videoTime":3.229702,"wordIdx":5,"wordPosInLine":0,"lineIdx":4},{"systemTime":1395090168784,"videoTime":3.48031,"wordIdx":6,"wordPosInLine":1,"lineIdx":4},{"systemTime":1395090169122,"videoTime":3.987336,"wordIdx":7,"wordPosInLine":2,"lineIdx":4},{"systemTime":1395090169182,"videoTime":3.987336,"wordIdx":8,"wordPosInLine":3,"lineIdx":4},{"systemTime":1395090169239,"videoTime":3.987336,"wordIdx":9,"wordPosInLine":4,"lineIdx":4},{"systemTime":1395090170368,"videoTime":5.268495,"wordIdx":10,"wordPosInLine":0,"lineIdx":5},{"systemTime":1395090170771,"videoTime":5.51894,"wordIdx":11,"wordPosInLine":1,"lineIdx":5},{"systemTime":1395090171152,"videoTime":6.020212,"wordIdx":12,"wordPosInLine":0,"lineIdx":6},{"systemTime":1395090171635,"videoTime":6.52187,"wordIdx":13,"wordPosInLine":1,"lineIdx":6},{"systemTime":1395090171707,"videoTime":6.52187,"wordIdx":14,"wordPosInLine":2,"lineIdx":6},{"systemTime":1395090172741,"videoTime":7.525619,"wordIdx":15,"wordPosInLine":0,"lineIdx":7},{"systemTime":1395090173153,"videoTime":8.04391,"wordIdx":16,"wordPosInLine":1,"lineIdx":7}]
  logs = JSON.parse require('fs').readFileSync('darkhorselog.json', 'utf-8')
  #console.log logs
  timeList = logsToTimeList logs
  #console.log timeList
  #console.log timeList
  #compute_time_word_path = require('./alignment_core2').compute_time_word_path
  time_word_path = compute_time_word_path timeList
  console.log JSON.stringify(time_word_path)

main() if module? and require.main is module

#console.log compute_time_word_path [[1, 0, 0], [0, 1, 0], [0, 1, 0], [0, 0, 1], [0, 0, 1] ]
