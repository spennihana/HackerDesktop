package com.hnd.util

import org.joda.time.DateTime
import org.joda.time.format.DateTimeFormat

/**
 * Simple Timer class.
 */
class Timer {

  internal val _start = System.currentTimeMillis()
  /**Return the difference between when the timer was created and the current time.  */
  fun time(): Long {
    return System.currentTimeMillis() - _start
  }

  /** Return the difference between when the timer was created and the current
   * time as a string along with the time of creation in date format.  */
  override fun toString(): String {
    val now = System.currentTimeMillis()
    return PrettyPrint.msecs(now - _start, false) + " (Wall: " + longFormat.print(now) + ") "
  }

  companion object {

    private val longFormat = DateTimeFormat.forPattern("dd-MMM HH:mm:ss.SSS")
    private val logFormat = DateTimeFormat.forPattern("MM-dd HH:mm:ss.SSS")

    /**
     * Used by Logging (Log.java) for creating a timestamp in front of each output line.
     */
    internal fun nowAsLogString(): String {
      return logFormat.print(DateTime.now())
    }
  }
}
