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
  fun newStories():String  { return "$HN_URL/new$STORIES" }
  fun topStories():String  { return "$HN_URL/top$STORIES" }
  fun bestStories():String { return "$HN_URL/best$STORIES"}
  fun askStories():String  { return "$HN_URL/ask$STORIES" }
  fun showStories():String { return "$HN_URL/show$STORIES"}
  fun jobStories():String  { return "$HN_URL/job$STORIES" }

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