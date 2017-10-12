package com.hnd

import com.google.gson.Gson
import com.hnd.util.Log
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL


object HN {
  val HN_API_VERSION = "v0"
  val HN_URL = "https://hacker-news.firebaseio.com/$HN_API_VERSION"
  val STORIES= "stories.json"

  // item
  fun item(item: Int):String { return "$HN_URL/item/$item.json"}

  // stories
  fun storiesURL(story:String):String { return "$HN_URL/$story$STORIES"}

  // updates
  fun updates():String { return "$HN_URL/updates.json"}

  fun hnRequest(url: String): String {
    Log.info("Making HN request with url: " + url)
    val hn = URL(url)
    with(hn.openConnection() as HttpURLConnection) {
      Log.info("Response: $responseCode")
      BufferedReader(InputStreamReader(inputStream)).use {
        val res = StringBuffer()
        var line = it.readLine()
        var i =0
        while( line!=null ) {
          res.append(line)
          line = it.readLine()
          i++
          if( i%1000 ==0 )
            Log.info("Got i: " + i)
        }
        return res.toString()
      }
    }
  }
}

data class Item(val item:String, var sort:Int)
data class Comment(val comment: String?, var depth:Int, val kids: Array<Comment?>?)
class StoryCache(val story:String) {
  init { fetchAll() }
  var _ids: IntArray? = null
  var _fetchedSoFar:Int = 0
  val _cache: MutableMap<Int,String> = mutableMapOf()
  val _comments: MutableMap<Int,Array<Comment?>> = mutableMapOf()
  val _depthMap: MutableMap<Int, Int> = mutableMapOf() // know depth of parent
  fun fetchAll() {
    val res = HN.hnRequest(HN.storiesURL(story))
    _ids = Gson().fromJson(res, IntArray::class.java)
    if( _ids==null )
      throw IllegalStateException("Unable to fetch $story stories")
  }
  fun reset() {
    _fetchedSoFar=0
    _comments.clear()
    _depthMap.clear()
  }

  fun refresh() {
    _cache.clear()
    reset()
    fetchAll()
  }

  private fun range(index: IntArray?, start: Int, cnt: Int): IntArray? {
    if( index==null ) return null
    var start = start
    var cnt = cnt
    if( start < 0 || start > index.size )
      return null
    if( start + cnt > index.size )
      cnt = index.size - start

    val res = IntArray(cnt)
    var i = 0
    while (i < cnt) res[i++] = index[start++]
    _fetchedSoFar += cnt
    return res
  }

  // comments are a recursive structure as follows:
  //    id -> [c0,c1,...,cn]
  // each comment is some text and a list of 0 or more responses
  // we're only ever concerned in a single layer at a time (fewer requests)
  // track the depth with a global map of comment depth
  //
  // semantics of the _comments cache:
  //    if an id is not found in _comments, then the id is a story id
  //    if an id is found, then it's a story or parent comment
  //      if there are no kids, then fetch kids
  //    return kids
  fun getComments(pid:Int, cids:IntArray?):String {
    if( cids==null || cids.isEmpty() ) return ""
    if( _comments[pid]==null || _comments[pid]!!.isEmpty() ) { // only occurs if pid is a story id
      assert(_cache[pid]!=null)  // assert pid is a story id
      val kids = arrayOfNulls<Comment>(cids.size)
      var i=0
      val depth = if(_depthMap[pid]==null ) 0 else (1+_depthMap[pid]!!)
      for(id in cids) {
        kids[i++] = Comment(HN.hnRequest(HN.item(id)), depth, null)
        _comments[id] = emptyArray() // flag the next level as empty array
        _depthMap[id] = depth
      }
      _comments[pid] = kids
    }
    val sb = StringBuilder("[")
    val comments = _comments[pid] ?: return ""
    for(comment in comments)
      sb.append(comment?.comment).append(",")
    sb.deleteCharAt(sb.lastIndex).append("]")
    return StringBuilder("{")
        .append("\"parent\":").append(pid).append(",")
        .append("\"depth\":").append(_depthMap[cids[0]]).append(",")
        .append("\"comments\":").append(sb.toString())
        .append("}")
        .toString()
  }

  fun loadMore(nToFetch:Int):String {
    val ids = range(_ids, _fetchedSoFar, nToFetch) ?: return ""
    val sb: StringBuilder = StringBuilder("[")
    for(id in ids) {
      if( _cache[id]==null) _cache[id] = HN.hnRequest(HN.item(id))
      sb.append(_cache[id]).append(",")
    }
    sb.deleteCharAt(sb.lastIndex).append("]")
    return sb.toString()
  }
}