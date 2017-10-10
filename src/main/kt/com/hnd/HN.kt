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
  var _ids: IntArray? = null
  fun getAll() {
    val res = HN.hnRequest(HN.storiesURL(story))
  }

}