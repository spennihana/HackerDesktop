package com.hnd.util

import com.hnd.HackerDesktop
import org.apache.log4j.LogManager
import org.apache.log4j.Logger
import org.apache.log4j.PropertyConfigurator
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.util.*

/** Log for HackerDesktop.
 */
object Log {

  private var _logger: org.apache.log4j.Logger? = null
  internal var LOG_DIR: String? = null

  val FATAL: Int = 0
  val ERRR: Int = 1
  val WARN: Int = 2
  val INFO: Int = 3
  val DEBUG: Int = 4
  val TRACE: Int = 5
  val LVLS = arrayOf("FATAL", "ERRR", "WARN", "INFO", "DEBUG", "TRACE")
  internal var _level = INFO
  var quiet = false

  // Common pre-header
  private var _preHeader: String? = null

  fun valueOf(slvl: String?): Int {
    var s: String? = slvl ?: return -1
    s = s!!.toLowerCase()
    if (s.startsWith("fatal")) return FATAL
    if (s.startsWith("err")) return ERRR
    if (s.startsWith("warn")) return WARN
    if (s.startsWith("info")) return INFO
    if (s.startsWith("debug")) return DEBUG
    if (s.startsWith("trace")) return TRACE
    return -1
  }

  fun init(slvl: String, quiet: Boolean) {
    val lvl = valueOf(slvl)
    if (lvl != -1) _level = lvl
    this.quiet = quiet
  }

  fun trace(vararg objs: Any) { log(TRACE, *objs) }
  fun debug(vararg objs: Any) { log(DEBUG, *objs) }
  fun info(vararg objs: Any)  { log(INFO , *objs) }
  fun warn(vararg objs: Any)  { log(WARN , *objs) }
  fun err(vararg objs: Any)   { log(ERRR , *objs) }

  fun err(ex: Throwable) {
    val sw = StringWriter()
    ex.printStackTrace(PrintWriter(sw))
    err(sw.toString())
  }
  fun fatal(vararg objs: Any) { log(FATAL, *objs) }
  @Suppress("unchecked_cast")
  fun log(level: Int, vararg objs: Any) { if (_level >= level) write(level, objs as Array<Any>) }
  fun info(s: String, stdout: Boolean) { if (_level >= INFO) write0(INFO, stdout, s) }

  private fun write(lvl: Int, objs: Array<Any>) {
    val writeToStdout = lvl <= _level
    write0(lvl, writeToStdout, objs)
  }

  private fun write0(lvl: Int, stdout: Boolean, objs: Array<Any>) {
    val sb = StringBuilder()
    for (o in objs) sb.append(o)
    val res = sb.toString()
    _preHeader = fixedLength(HackerDesktop._endpoint + " ", 8) + fixedLength(HackerDesktop.PID + " ", 4)
    if (INIT_MSGS != null) {   // Ahh, dump any initial buffering
      val bufmsgs = INIT_MSGS
      INIT_MSGS = null
      if (bufmsgs != null) for (s in bufmsgs) write0(INFO, true, s)
    }
    write0(lvl, stdout, res)
  }

  private fun write0(lvl: Int, stdout: Boolean, s: String) {
    val sb = StringBuilder()
    val hdr = header(lvl)   // Common header for all lines
    write0(sb, hdr, s)

    // stdout first - in case log4j dies failing to init or write something
    if (stdout && !quiet) println(sb)

    // log something here
    val l4j = (if (_logger != null) _logger else createLog4j()) ?: throw RuntimeException("Could not log...")
    when (lvl) {
      FATAL -> l4j.fatal(sb)
      ERRR -> l4j.error(sb)
      WARN -> l4j.warn(sb)
      INFO -> l4j.info(sb)
      DEBUG -> l4j.debug(sb)
      TRACE -> l4j.trace(sb)
      else -> {
        l4j.error("Invalid log level requested")
        l4j.error(s)
      }
    }
  }

  private fun write0(sb: StringBuilder, hdr: String, s: String) {
    if (s.contains("\n")) {
      for (s2 in s.split("\n".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()) {
        write0(sb, hdr, s2)
        sb.append("\n")
      }
      sb.setLength(sb.length - 1)
    } else {
      sb.append(hdr).append(s)
    }
  }

  // Build a header for all lines in a single message
  private fun header(lvl: Int): String {
    val nowString = Timer.nowAsLogString()
    val s = nowString + " " + _preHeader + " " +
        fixedLength(Thread.currentThread().name + " ", 10) +
        LVLS[lvl] + ": "
    return s
  }

  // A little bit of startup buffering
  private var INIT_MSGS: ArrayList<String>? = ArrayList()

  fun flushStdout() {
    if (INIT_MSGS != null) {
      for (s in INIT_MSGS!!) {
        println(s)
      }

      INIT_MSGS!!.clear()
    }
  }

  /**
   * @return This is what should be used when doing Download All Logs.
   */
  val logDir: String
    @Throws(Exception::class)
    get() {
      if (LOG_DIR == null) {
        throw Exception("LOG_DIR not yet defined")
      }

      return LOG_DIR as String
    }

  private val logFileNameStem: String
    @Throws(Exception::class) get() { return "hnd_" }

  /**
   * @return The common prefix for all of the different log files for this process.
   */
  val logPathFileNameStem: String
    @Throws(Exception::class)
    get() {
      val logFileName = logDir + File.separator + logFileNameStem
      return logFileName
    }

  /**
   * @return This is what shows up in the Web UI when clicking on show log file.  File name only.
   */
  @Throws(Exception::class)
  fun getLogFileName(level: String): String {
    val f: String
    when (level) {
      "trace" -> f = "-1-trace.log"
      "debug" -> f = "-2-debug.log"
      "info" -> f = "-3-info.log"
      "warn" -> f = "-4-warn.log"
      "error" -> f = "-5-error.log"
      "fatal" -> f = "-6-fatal.log"
      else -> throw Exception("Unknown level")
    }

    return logFileNameStem + f
  }

  @Throws(Exception::class)
  private fun setLog4jProperties(logDir: String, p: java.util.Properties) {
    LOG_DIR = logDir
    val logPathFileName = logPathFileNameStem

    // HackerDesktop-wide logging
    val appenders = arrayOf("TRACE, R6", "TRACE, R5, R6", "TRACE, R4, R5, R6", "TRACE, R3, R4, R5, R6", "TRACE, R2, R3, R4, R5, R6", "TRACE, R1, R2, R3, R4, R5, R6")[_level]
    p.setProperty("log4j.logger.hnd.default", appenders)
    p.setProperty("log4j.additivity.hnd.default", "false")

    p.setProperty("log4j.appender.R1", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R1.Threshold", "TRACE")
    p.setProperty("log4j.appender.R1.File", logPathFileName + "-1-trace.log")
    p.setProperty("log4j.appender.R1.MaxFileSize", "1MB")
    p.setProperty("log4j.appender.R1.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R1.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R1.layout.ConversionPattern", "%m%n")

    p.setProperty("log4j.appender.R2", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R2.Threshold", "DEBUG")
    p.setProperty("log4j.appender.R2.File", logPathFileName + "-2-debug.log")
    p.setProperty("log4j.appender.R2.MaxFileSize", "3MB")
    p.setProperty("log4j.appender.R2.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R2.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R2.layout.ConversionPattern", "%m%n")

    p.setProperty("log4j.appender.R3", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R3.Threshold", "INFO")
    p.setProperty("log4j.appender.R3.File", logPathFileName + "-3-info.log")
    p.setProperty("log4j.appender.R3.MaxFileSize", "2MB")
    p.setProperty("log4j.appender.R3.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R3.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R3.layout.ConversionPattern", "%m%n")

    p.setProperty("log4j.appender.R4", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R4.Threshold", "WARN")
    p.setProperty("log4j.appender.R4.File", logPathFileName + "-4-warn.log")
    p.setProperty("log4j.appender.R4.MaxFileSize", "256KB")
    p.setProperty("log4j.appender.R4.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R4.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R4.layout.ConversionPattern", "%m%n")

    p.setProperty("log4j.appender.R5", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R5.Threshold", "ERROR")
    p.setProperty("log4j.appender.R5.File", logPathFileName + "-5-error.log")
    p.setProperty("log4j.appender.R5.MaxFileSize", "256KB")
    p.setProperty("log4j.appender.R5.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R5.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R5.layout.ConversionPattern", "%m%n")

    p.setProperty("log4j.appender.R6", "org.apache.log4j.RollingFileAppender")
    p.setProperty("log4j.appender.R6.Threshold", "FATAL")
    p.setProperty("log4j.appender.R6.File", logPathFileName + "-6-fatal.log")
    p.setProperty("log4j.appender.R6.MaxFileSize", "256KB")
    p.setProperty("log4j.appender.R6.MaxBackupIndex", "3")
    p.setProperty("log4j.appender.R6.layout", "org.apache.log4j.PatternLayout")
    p.setProperty("log4j.appender.R6.layout.ConversionPattern", "%m%n")

    // Turn down the logging for some class hierarchies.
    p.setProperty("log4j.logger.org.apache.http", "WARN")
    p.setProperty("log4j.logger.com.amazonaws", "WARN")
    p.setProperty("log4j.logger.org.apache.hadoop", "WARN")
    p.setProperty("log4j.logger.org.jets3t.service", "WARN")
    p.setProperty("log4j.logger.org.reflections.Reflections", "ERROR")
    p.setProperty("log4j.logger.com.brsanthu.googleanalytics", "ERROR")
  }

  @Synchronized private fun createLog4j(): org.apache.log4j.Logger {
    if (_logger != null) return _logger as Logger // Test again under lock

    // Create some default properties on the fly if we aren't using a provided configuration.
    // HackerDesktop creates the log setup itself on the fly in code.
    val p = java.util.Properties()
    val dir = File(HackerDesktop._userData, "hndlog")
    setLog4jProperties(dir.toString(), p)
    PropertyConfigurator.configure(p)
    _logger = LogManager.getLogger("hnd.default")
    return _logger!!
  }

  fun fixedLength(s: String, length: Int): String {
    var r = padRight(s, length)
    if( r.length > length ) {
      val a = Math.max(r.length - length + 1, 0)
      val b = Math.max(a, r.length)
      r = "#" + r.substring(a, b)
    }
    return r
  }

  internal fun padRight(stringToPad: String, size: Int): String {
    val strb = StringBuilder(stringToPad)
    while (strb.length < size)
      if (strb.length < size) strb.append(' ')
    return strb.toString()
  }

  @JvmOverloads fun ignore(e: Throwable, msg: String = "[hnd] Problem ignored: ", printException: Boolean = true) {
    debug(msg + if (printException) e.toString() else "")
  }
}
