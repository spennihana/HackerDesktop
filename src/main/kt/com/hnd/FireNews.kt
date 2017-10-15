package com.hnd

import com.firebase.client.DataSnapshot
import com.firebase.client.Firebase
import com.firebase.client.ValueEventListener
import com.google.gson.Gson
import java.util.concurrent.Semaphore


object FireNews {
  val HN_API_VERSION = "v0"
  val HN_URL = "https://hacker-news.firebaseio.com/$HN_API_VERSION"
  val hnref = Firebase(HN_URL)

  fun item(item: Int):String { return "item/$item" }
  fun story(s: String):String{ return "${s}stories"}

  fun hnRequest(path: String): String {
    var s: String = ""
    val sem = Semaphore(0) // hack to do synchronous firebase calls
    hnref.child(path).addListenerForSingleValueEvent(object: ValueEventListener {
      override fun onDataChange(snap: DataSnapshot) {
        s = Gson().toJson(snap.value)
        sem.release()
      }
      override fun onCancelled(){}
    })
    sem.acquire()
    return s
  }

}

data class Item(val item:String, var sort:Int)
data class Comment(val comment: String?, var depth:Int, val kids: Array<Comment?>?)
class StoryCache(val story:String) {
  companion object {
    val NULL = Gson().toJson(null)
  }
  init { fetchAll() }
  var _ids: IntArray? = null
  var _fetchedSoFar:Int = 0
  val _cache: MutableMap<Int,String> = mutableMapOf()
  val _comments: MutableMap<Int,Array<Comment?>> = mutableMapOf()
  val _depthMap: MutableMap<Int, Int> = mutableMapOf() // know depth of parent
  fun fetchAll() {
    val res = FireNews.hnRequest(FireNews.story(story))
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

    if( cnt==0 ) return null

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
    if( cids==null || cids.isEmpty() ) return NULL
    if( _comments[pid]==null || _comments[pid]!!.isEmpty() ) { // only occurs if pid is a story id
      assert(_cache[pid]!=null)  // assert pid is a story id
      val kids = arrayOfNulls<Comment>(cids.size)
      var i=0
      val depth = if(_depthMap[pid]==null ) 0 else (1+_depthMap[pid]!!)
      for(id in cids) {
        kids[i++] = Comment(FireNews.hnRequest(FireNews.item(id)), depth, null)
        _comments[id] = emptyArray() // flag the next level as empty array
        _depthMap[id] = depth
      }
      _comments[pid] = kids
    }
    val sb = StringBuilder("[")
    val comments = _comments[pid] ?: return NULL
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
    val ids = range(_ids, _fetchedSoFar, nToFetch) ?: return NULL
    val sb: StringBuilder = StringBuilder("[")
    for(id in ids) {
      if( _cache[id]==null) _cache[id] = FireNews.hnRequest(FireNews.item(id))
      sb.append(_cache[id]).append(",")
    }
    sb.deleteCharAt(sb.lastIndex).append("]")
    return sb.toString()
  }
}