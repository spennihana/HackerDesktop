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
class StoryCache(val story:String) {
  companion object {
    const val ITEMS_PER_PAGE = 30
  }
  init { fetchAll() }
  var _ids: IntArray? = null
  var _fetchedSoFar:Int = 0
  fun fetchAll() {
    val res = HN.hnRequest(HN.storiesURL(story))
    _ids = Gson().fromJson(res, IntArray::class.java)
    if( _ids==null )
      throw IllegalStateException("Unable to fetch $story stories")
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

  fun loadMore(nToFetch:Int):String {
    val ids = range(_ids, _fetchedSoFar, nToFetch) ?: return Gson().toJson(null)
    val sb: StringBuilder = StringBuilder("[")
    for(id in ids)
      sb.append(HN.hnRequest(HN.item(id))).append(",")
    sb.deleteCharAt(sb.lastIndex).append("]")
    return sb.toString()
  }
}