package com.hnd

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
        while( line!=null ) {
          res.append(line)
          line = it.readLine()
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
//    val res = HN.hnRequest(HN.storiesURL(story))
//    _ids = Gson().fromJson(res, IntArray::class.java)
//    if( _ids==null )
//      throw IllegalStateException("Unable to fetch $story stories")
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

  val s = """{"by":"gsempe","descendants":23,"id":15424437,"kids":[15426103,15425772,15427111,15426279,15428238,15428066,15428070,15428900,15425971],"score":240,"time":1507394136,"title":"A Simple Approach to Building a Real-Time Collaborative Text Editor","type":"story","url":"http://digitalfreepen.com/2017/10/06/simple-real-time-collaborative-text-editor.html"}"""

  fun loadMore(nToFetch:Int):String {
    return "[$s]"
//    val ids = range(_ids, _fetchedSoFar, nToFetch) ?: return Gson().toJson(null)
//    val stories = arrayOfNulls<String>(ids.size)
//    var i=0
//    for(id in ids)
//      stories[i++] = HN.hnRequest(HN.item(id))
//    return Gson().toJson(stories)
  }
}