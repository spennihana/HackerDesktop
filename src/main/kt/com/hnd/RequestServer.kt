package com.hnd

import com.hnd.util.Log
import spark.Request
import spark.Response
import spark.Spark

class RequestServer(val port: Int) {
  fun boot() {
    Spark.port(port)
    Spark.get("/hello", { req,res -> handler(req,res, {req,res -> "Hello Spark!!!" })})

    Spark.path("/top") {
      Spark.get("",    { req,res -> handler(req,res, {req,res -> HN.hnRequest(HN.topStories())}) })
      Spark.get("/:n", { req,res -> handler(req,res, {req,res -> ""}) })
    }
  }

  fun handler(request:Request, response:Response, h: (request:Request, response:Response) -> String): String {
    Log.info("Handling Route: " + request.pathInfo())
    return h(request,response)
  }
}