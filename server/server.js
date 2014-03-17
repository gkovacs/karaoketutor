// Generated by LiveScript 1.2.0
var root;
root = typeof global != 'undefined' && global !== null ? global : window;
Meteor.methods({
  getVideoSnippet: function(videoID){
    var cachedSnippet, snippetResult, snippet;
    if (videoID == null || videoID === '') {
      return null;
    }
    cachedSnippet = YoutubeSnippets.findOne({
      _id: videoID
    });
    if (cachedSnippet != null) {
      return cachedSnippet;
    }
    snippetResult = Meteor.http.get('https://www.googleapis.com/youtube/v3/videos', {
      params: {
        part: 'snippet',
        id: videoID,
        key: 'AIzaSyBF98nsRWUqQf8odyMQ805WxhdQpg6-BpM'
      }
    });
    snippet = snippetResult.data;
    snippet._id = videoID;
    snippet.time_added = new Date().getTime();
    YoutubeSnippets.insert(snippet);
    return YoutubeSnippets.findOne({
      _id: videoID
    });
  },
  clientCall: function(clientId, method, args, callback){
    console.log('clientId is:' + clientId);
    return Meteor.ClientCall.apply(clientId, method, args, callback);
  }
});
Meteor.startup(function(){
  if (Songs.find().count() === 0) {
    Songs.insert({
      name: 'Katy Perry - Dark Horse (Official) ft. Juicy J',
      url: 'http://www.youtube.com/watch?v=0KSOMA3QBU0',
      videoID: '0KSOMA3QBU0',
      _id: '0KSOMA3QBU0',
      time_added: new Date().getTime(),
      thumbs_up: 0,
      thumbs_down: 0,
      lyricIDs: []
    });
    return Songs.insert({
      name: 'John Legend - All of Me',
      url: 'http://www.youtube.com/watch?v=450p7goxZqg',
      videoID: '450p7goxZqg',
      _id: '450p7goxZqg',
      time_added: new Date().getTime(),
      thumbs_up: 0,
      thumbs_down: 0,
      lyricIDs: []
    });
  }
});