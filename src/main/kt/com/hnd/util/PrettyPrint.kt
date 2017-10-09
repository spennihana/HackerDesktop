package com.hnd.util

import org.joda.time.DurationFieldType
import org.joda.time.Period
import org.joda.time.PeriodType
import org.joda.time.format.PeriodFormat
import java.util.*
import java.util.concurrent.TimeUnit


object PrettyPrint {
  fun msecs(msecs: Long, truncate: Boolean): String {
    var msec = msecs
    val hr = TimeUnit.MILLISECONDS.toHours(msec)
    msec -= TimeUnit.HOURS.toMillis(hr)
    val min = TimeUnit.MILLISECONDS.toMinutes(msec)
    msec -= TimeUnit.MINUTES.toMillis(min)
    val sec = TimeUnit.MILLISECONDS.toSeconds(msec)
    msec -= TimeUnit.SECONDS.toMillis(sec)
    val ms = TimeUnit.MILLISECONDS.toMillis(msec)
    if( !truncate ) return String.format("%02d:%02d:%02d.%03d", hr, min, sec, ms)
    if( hr != 0L  ) return String.format("%2d:%02d:%02d.%03d", hr, min, sec, ms)
    if( min != 0L ) return String.format("%2d min %2d.%03d sec", min, sec, ms)
    return String.format("%2d.%03d sec", sec, ms)
  }

  fun usecs(usecs: Long): String {
    var us = usecs
    val hr = TimeUnit.MICROSECONDS.toHours(us)
    us -= TimeUnit.HOURS.toMicros(hr)
    val min = TimeUnit.MICROSECONDS.toMinutes(us)
    us -= TimeUnit.MINUTES.toMicros(min)
    val sec = TimeUnit.MICROSECONDS.toSeconds(us)
    us -= TimeUnit.SECONDS.toMicros(sec)
    val ms = TimeUnit.MICROSECONDS.toMillis(us)
    us -= TimeUnit.MILLISECONDS.toMicros(ms)
    if( hr  != 0L) return String.format("%2d:%02d:%02d.%03d", hr, min, sec, ms)
    if( min != 0L) return String.format("%2d min %2d.%03d sec", min, sec, ms)
    if( sec != 0L) return String.format("%2d.%03d sec", sec, ms)
    if( ms  != 0L) return String.format("%3d.%03d msec", ms, us)
    return String.format("%3d usec", us)
  }

  fun toAge(from: Date?, to: Date?): String {
    if (from == null || to == null) return "N/A"
    val period = Period(from.time, to.time)
    val dtf = object : ArrayList<DurationFieldType>() {
      init {
        add(DurationFieldType.years())
        add(DurationFieldType.months())
        add(DurationFieldType.days())
        if (period.years == 0 && period.months == 0 && period.days == 0) {
          add(DurationFieldType.hours())
          add(DurationFieldType.minutes())
        }

      }
    }.toTypedArray()

    val pf = PeriodFormat.getDefault()
    return pf.print(period.normalizedStandard(PeriodType.forFields(dtf)))
  }

  // Return X such that (bytes < 1L<<(X*10))
  internal fun byteScale(bytes: Long): Int {
    if (bytes < 0) return -1
    for (i in 0..5)
      if (bytes < 1L shl i * 10)
        return i
    return 6
  }

  internal fun bytesScaled(bytes: Long, scale: Int): Double {
    if (scale <= 0) return bytes.toDouble()
    return bytes / (1L shl (scale - 1) * 10).toDouble()
  }

  internal val SCALE = arrayOf("N/A (-ve)", "Zero  ", "%4.0f  B", "%.1f KB", "%.1f MB", "%.2f GB", "%.3f TB", "%.3f PB")
  fun bytes(bytes: Long): String {
    return bytes(bytes, byteScale(bytes))
  }

  internal fun bytes(bytes: Long, scale: Int): String {
    return String.format(SCALE[scale + 1], bytesScaled(bytes, scale))
  }

  fun bytesPerSecond(bytes: Long): String {
    if (bytes < 0) return "N/A"
    return bytes(bytes) + "/S"
  }

  internal var powers10 = doubleArrayOf(0.0000000001, 0.000000001, 0.00000001, 0.0000001, 0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.1, 1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0)

  var powers10i = longArrayOf(1L, 10L, 100L, 1000L, 10000L, 100000L, 1000000L, 10000000L, 100000000L, 1000000000L, 10000000000L, 100000000000L, 1000000000000L, 10000000000000L, 100000000000000L, 1000000000000000L, 10000000000000000L, 100000000000000000L, 1000000000000000000L)

  fun pow10(exp: Int): Double {
    return if (exp >= -10 && exp <= 10) powers10[exp + 10] else Math.pow(10.0, exp.toDouble())
  }

  fun pow10i(exp: Int): Long {
    return if (exp > -1 && exp < 19) powers10i[exp] else Math.pow(10.0, exp.toDouble()).toLong()
  }

  fun fitsIntoInt(d: Double): Boolean {
    return Math.abs(d.toInt() - d) < 1e-8
  }


  // About as clumsy and random as a blaster...
  fun UUID(lo: Long, hi: Long): String {
    val lo0 = lo shr 32 and 0xFFFFFFFFL
    val lo1 = lo shr 16 and 0xFFFFL
    val lo2 = lo shr 0 and 0xFFFFL
    val hi0 = hi shr 48 and 0xFFFFL
    val hi1 = hi shr 0 and 0xFFFFFFFFFFFFL
    return String.format("%08X-%04X-%04X-%04X-%012X", lo0, lo1, lo2, hi0, hi1)
  }

  fun uuid(uuid: java.util.UUID?): String {
    return if (uuid == null) "(N/A)" else UUID(uuid.leastSignificantBits, uuid.mostSignificantBits)
  }

  private fun x2(d: Double, scale: Double): String {
    var s = java.lang.Double.toString(d)
    // Double math roundoff error means sometimes we get very long trailing
    // strings of junk 0's with 1 digit at the end... when we *know* the data
    // has only "scale" digits.  Chop back to actual digits
    val ex = Math.log10(scale).toInt()
    val x = s.indexOf('.')
    val y = x + 1 + -ex
    if (x != -1 && y < s.length) s = s.substring(0, x + 1 + -ex)
    while (s[s.length - 1] == '0')
      s = s.substring(0, s.length - 1)
    return s
  }

  fun formatPct(pct: Double): String {
    var s = "N/A"
    if( !pct.isNaN() )
      s = String.format("%5.2f %%", 100 * pct)
    return s
  }

  /**
   * This method takes a number, and returns the
   * string form of the number with the proper
   * ordinal indicator attached (e.g. 1->1st, and 22->22nd)
   * @param i - number to have ordinal indicator attached
   * *
   * @return string form of number along with ordinal indicator as a suffix
   */
  fun withOrdinalIndicator(i: Long): String {
    val ord: String
    // Grab second to last digit
    var d = (Math.abs(i) / Math.pow(10.0, 1.0)).toInt() % 10
    if (d == 1)
      ord = "th" //teen values all end in "th"
    else { // not a weird teen number
      d = (Math.abs(i) / Math.pow(10.0, 0.0)).toInt() % 10
      when (d) {
        1 -> ord = "st"
        2 -> ord = "nd"
        3 -> ord = "rd"
        else -> ord = "th"
      }
    }
    return i.toString() + ord
  }
}
