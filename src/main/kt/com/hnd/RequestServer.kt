package com.hnd

import com.hnd.Handlers.doGet
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
    Spark.get("/:story/:n", {req,res -> genericHandler(req,res, ::doGet)})
    Spark.get("/reset", {req,res -> genericHandler(req,res, ::reset)})
  }
}

object Handlers {
  fun doGet(request:Request, response:Response):String {
    var story = request.params("story")
    if( story=="jobs" ) story="job"
    return HackerDesktop._storyMap[story]!!.loadMore(request.params("n").toInt())
  }

  fun reset(request:Request, response:Response):String {
    HackerDesktop.reset()
    return ""
  }
}