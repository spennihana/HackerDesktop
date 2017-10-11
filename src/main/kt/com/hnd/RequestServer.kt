package com.hnd

import com.google.gson.Gson
import com.hnd.Handlers.getComments
import com.hnd.Handlers.getStories
import com.hnd.Handlers.reset
import com.hnd.util.Log
import spark.Filter
import spark.Request
import spark.Response
import spark.Spark

class RequestServer(val port: Int) {

  fun genericHandler(request:Request, response:Response, h: (request:Request, response:Response) -> String): String {
    Log.info("Handling Route: " + request.pathInfo())
    return h(request,response)
  }

  fun registeRoute(route:String, h: (request:Request, response:Response) -> String) {
    Spark.get(route, {req,res -> genericHandler(req,res,h)})
  }

  fun boot() {
    Spark.port(port)
    Spark.options("/*", {req, res ->
      val accessControlReqHeaders = req.headers("Access-Control-Request-Headers")
      if( accessControlReqHeaders!=null )
        res.header("Access-Control-Allow-Headers", accessControlReqHeaders)

      val accessControlRequestMethod = req.headers("Access-Control-Request-Method")
      if (accessControlRequestMethod != null)
        res.header("Access-Control-Allow-Methods", accessControlRequestMethod)
      return@options "OK"
    })
    Spark.before(Filter { _, res ->
      res.header("Access-Control-Allow-Origin", "*")
      res.header("Access-Control-Request-Method", "GET")
      res.header("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Requested-With,Content-Length,Accept,Origin,")
      res.type("application/json")
    })

    // custom routes
    registeRoute("/:story/:n", ::getStories)
    registeRoute("/reset/", ::reset)
    registeRoute("/:pid/:cids", ::getComments)
  }
}

object Handlers {

  fun getStory(story:String):String {
    if( story=="jobs" ) return "job"   // FIXME: this is really a display hack; make everything a job, and display does job -> jobs
    return story
  }

  fun getStories(request:Request, response:Response):String {
    return HackerDesktop._storyMap[getStory(request.params("story"))]!!.loadMore(request.params("n").toInt())
  }

  fun reset(request:Request, response:Response):String {
    HackerDesktop.reset()
    return ""
  }

  fun getComments(request:Request, response:Response):String {
    val story = getStory(request.params("story"))
    val pid = request.params("pid").toInt()
    val cids = Gson().fromJson(request.params("cids"), IntArray::class.java)
    return HackerDesktop._storyMap[story]!!.getComments(pid, cids)
  }
}