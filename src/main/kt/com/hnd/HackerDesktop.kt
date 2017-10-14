package com.hnd

import com.hnd.util.Log
import java.lang.management.ManagementFactory


fun main(args: Array<String>) {
  val logdir = if(args.isEmpty()) System.getProperty("user.dir") else args[0]
  HackerDesktop(3984, logdir)
}

class HackerDesktop(val port: Int, userDataPath: String) {
  companion object {
    lateinit var _userData: String
    lateinit var _endpoint: String
    lateinit var PID: String
    lateinit var _server: RequestServer
    val _storyMap: MutableMap<String, StoryCache> = mutableMapOf()
    fun reset() { _storyMap.values.map { it.reset() } }
  }
  fun initStories() { arrayOf("new", "top", "best", "ask", "show", "job").map { _storyMap.put(it, StoryCache(it)) } }

  init {
    _userData = userDataPath
    _endpoint = "*:" + port
    PID="-1L"
    val n = ManagementFactory.getRuntimeMXBean().name
    val i = n.indexOf('@')
    if (i != -1) PID = java.lang.Long.parseLong(n.substring(0, i)).toString()

    // init the rest server endpoints
    _server = RequestServer(port)
    _server.boot()
    Log.info("==========Hacker Desktop==========")
    Log.info("Internal server started at: " + _endpoint)
    Log.info("Log directory: " + _userData)
    Log.info("Firebase: " + FireNews.hnref)
    initStories()
    Log.info("booted")
  }
}