package com.hnd

import com.hnd.Handlers.getAsk
import com.hnd.Handlers.getBest
import com.hnd.Handlers.getJobs
import com.hnd.Handlers.getNew
import com.hnd.Handlers.getShow
import com.hnd.Handlers.getTop
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

    Spark.before(Filter { req, res ->
      res.header("Access-Control-Allow-Origin", "*")
      res.header("Access-Control-Request-Method", "GET")
      res.header("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Requested-With,Content-Length,Accept,Origin,")
      res.type("application/json")
    })

    Spark.get("/hello", { req,res -> genericHandler(req,res, {_,_ -> "Hello Spark!!!" }) })
    Spark.get("/New/:n", { req,res -> genericHandler(req,res, ::getNew) })
    Spark.get("/Top/:n", { req,res -> genericHandler(req,res, ::getTop) })
    Spark.get("/Best/:n", { req,res -> genericHandler(req,res, ::getBest) })
    Spark.get("/Ask/:n", { req,res -> genericHandler(req,res, ::getAsk) })
    Spark.get("/Show/:n", { req,res -> genericHandler(req,res, ::getShow) })
    Spark.get("/Jobs/:n", { req,res -> genericHandler(req,res, ::getJobs) })
  }
}

object Handlers {
  fun getNew(request:Request, response:Response):String {
    return "[new,1,2,3]"
  }

  fun getTop(request:Request, response:Response):String {
    return "[\"top\",\"1\",\"2\",\"3\",\"top\",\"1\",\"2\",\"3\",\"top\",\"1\",\"2\",\"3\"]"
  }

  fun getBest(request:Request, response:Response):String {
    return ""
  }

  fun getAsk(request:Request, response:Response):String {
    return ""
  }

  fun getShow(request:Request, response:Response):String {
    return ""
  }

  fun getJobs(request:Request, response:Response):String {
    return ""
  }
}