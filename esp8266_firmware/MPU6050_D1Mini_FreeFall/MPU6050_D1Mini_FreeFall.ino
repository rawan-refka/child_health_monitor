/*
 * ESP8266 D1 mini + MPU6050 (I2C) — نسخة بسيطة
 *
 * التوصيل:
 *   VCC -> 3.3V
 *   GND -> GND
 *   SDA -> D2 (GPIO4)
 *   SCL -> D1 (GPIO5)
 *   عنوان I2C: 0x68 (AD0 -> GND)
 *
 * Serial Plotter: SERIAL_PLOTTER_OUTPUT = 1 (افتراضي).
 *   أدوات → Serial Plotter، 115200. أول سطر = أسماء القنوات، ثم أرقام فقط.
 *   أثناء المعايرة الوميض = لا تحرك الحساس. للنص العربي المفصل عيّن 0.
 */

#include <Wire.h>

/** 1 = خرج CSV فقط (مناسب Serial Plotter) | 0 = نص عربي مفصّل في loop */
#ifndef SERIAL_PLOTTER_OUTPUT
#define SERIAL_PLOTTER_OUTPUT 1
#endif

static const uint8_t MPU_ADDR = 0x68;

static const uint8_t REG_PWR_MGMT_1 = 0x6B;
static const uint8_t REG_ACCEL_XOUT_H = 0x3B;
static const uint8_t REG_ACCEL_CONFIG = 0x1C;
static const uint8_t REG_GYRO_CONFIG = 0x1B;

static const float ACCEL_LSB_PER_G = 16384.0f;
static const float GYRO_LSB_PER_DPS = 131.0f;

static const float FREE_FALL_G_THRESHOLD = 0.35f;
static const uint32_t FREE_FALL_HOLD_MS = 120;
static const float IMPACT_G_THRESHOLD = 2.5f;

#if SERIAL_PLOTTER_OUTPUT
static const uint32_t PLOT_INTERVAL_MS = 25;
#else
static const uint32_t PRINT_INTERVAL_MS = 120;
#endif

static uint32_t freeFallStartMs = 0;
static bool inFreeFall = false;
static bool warnedFreeFall = false;
#if SERIAL_PLOTTER_OUTPUT
static uint8_t impactShowCount = 0;
#endif

/** انحراف صفري للجيروسكوب (°/s) — يُحسب عند السكون في setup */
static float gyroOffX = 0.0f;
static float gyroOffY = 0.0f;
static float gyroOffZ = 0.0f;

static const uint16_t GYRO_CAL_SAMPLES = 256;

static void mpuWrite(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission(true);
}

static uint8_t mpuRead8(uint8_t reg) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom((int)MPU_ADDR, 1);
  return Wire.available() ? Wire.read() : 0;
}

static void mpuReadAccelGyro(int16_t* ax, int16_t* ay, int16_t* az, int16_t* gx, int16_t* gy, int16_t* gz) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(REG_ACCEL_XOUT_H);
  Wire.endTransmission(false);
  Wire.requestFrom((int)MPU_ADDR, 14);

  auto rd16 = []() -> int16_t {
    uint8_t h = Wire.read();
    uint8_t l = Wire.read();
    return (int16_t)((h << 8) | l);
  };

  *ax = rd16();
  *ay = rd16();
  *az = rd16();
  (void)Wire.read();
  (void)Wire.read();
  *gx = rd16();
  *gy = rd16();
  *gz = rd16();
}

static bool mpuBegin() {
  mpuWrite(REG_PWR_MGMT_1, 0x00);
  delay(50);
  mpuWrite(REG_ACCEL_CONFIG, 0x00);
  mpuWrite(REG_GYRO_CONFIG, 0x00);
  delay(10);
  return mpuRead8(0x75) == 0x68;
}

/** معايرة الجيروسكوب: ضع اللوحة ساكنة تماماً أثناء أخذ العينات */
static void calibrateGyroAtRest() {
#if SERIAL_PLOTTER_OUTPUT
  pinMode(LED_BUILTIN, OUTPUT);
#else
  Serial.println();
  Serial.println(F(">>> معايرة الجيروسكوب (انحراف صفري) <<<"));
  Serial.println(F("    اترك الحساس ساكناً بدون لمس لمدة ~1 ثانية..."));
#endif
  delay(300);

  int64_t sx = 0, sy = 0, sz = 0;
  for (uint16_t i = 0; i < GYRO_CAL_SAMPLES; i++) {
#if SERIAL_PLOTTER_OUTPUT
    digitalWrite(LED_BUILTIN, (i / 32) & 1);
#endif
    int16_t ax, ay, az, gx, gy, gz;
    mpuReadAccelGyro(&ax, &ay, &az, &gx, &gy, &gz);
    sx += gx;
    sy += gy;
    sz += gz;
    delay(4);
  }
#if SERIAL_PLOTTER_OUTPUT
  digitalWrite(LED_BUILTIN, HIGH);
#endif
  const float n = (float)GYRO_CAL_SAMPLES;
  gyroOffX = (float)sx / n / GYRO_LSB_PER_DPS;
  gyroOffY = (float)sy / n / GYRO_LSB_PER_DPS;
  gyroOffZ = (float)sz / n / GYRO_LSB_PER_DPS;

#if !SERIAL_PLOTTER_OUTPUT
  Serial.print(F("    تم. تعويض الجيرو (°/s): X="));
  Serial.print(gyroOffX, 2);
  Serial.print(F("  Y="));
  Serial.print(gyroOffY, 2);
  Serial.print(F("  Z="));
  Serial.println(gyroOffZ, 2);
  Serial.println();
#endif
}

#if SERIAL_PLOTTER_OUTPUT
static void printPlotterHeader() {
  // أسماء قصيرة ASCII — تظهر كأسماء قنوات في Serial Plotter
  Serial.println(F("ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,mag_g,freefall,impact"));
}
#endif

void setup() {
  Serial.begin(115200);
  delay(200);

  Wire.begin(D2, D1);
  Wire.setClock(100000);

  if (!mpuBegin()) {
    Serial.println(F("خطأ: لم يُعثر على MPU6050 — تحقق من التوصيل (SDA=D2, SCL=D1) والعنوان 0x68."));
    while (true) delay(1000);
  }

#if SERIAL_PLOTTER_OUTPUT
  calibrateGyroAtRest();
  printPlotterHeader();
#else
  Serial.println();
  Serial.println(F("=== MPU6050 + D1 mini ==="));
  Serial.println(F("MPU6050 جاهز."));
  calibrateGyroAtRest();
  Serial.println(F("--- حرّك الحساس؛ للسقوط الحر: أفلت بحذر فوق سطح ناعم ---"));
  Serial.println();
  Serial.println(F("============================================================"));
  Serial.println(F("  التسارع = g (ثقل الجاذبية)    |    الجيرو = درجة/ثانية"));
  Serial.println(F("  المقدار ~ 1.0 g عند السكون (اتجاه الجاذبية)"));
  Serial.println(F("============================================================"));
  Serial.println();
#endif
}

void loop() {
  int16_t rax, ray, raz, rgx, rgy, rgz;
  mpuReadAccelGyro(&rax, &ray, &raz, &rgx, &rgy, &rgz);

  float ax = rax / ACCEL_LSB_PER_G;
  float ay = ray / ACCEL_LSB_PER_G;
  float az = raz / ACCEL_LSB_PER_G;
  float gx = rgx / GYRO_LSB_PER_DPS - gyroOffX;
  float gy = rgy / GYRO_LSB_PER_DPS - gyroOffY;
  float gz = rgz / GYRO_LSB_PER_DPS - gyroOffZ;

  float mag = sqrtf(ax * ax + ay * ay + az * az);

  uint32_t now = millis();

  if (mag < FREE_FALL_G_THRESHOLD) {
    if (freeFallStartMs == 0) freeFallStartMs = now;
    if (!inFreeFall && (now - freeFallStartMs) >= FREE_FALL_HOLD_MS) {
      inFreeFall = true;
#if !SERIAL_PLOTTER_OUTPUT
      if (!warnedFreeFall) {
        warnedFreeFall = true;
        Serial.println();
        Serial.println(F(">>> تنبيه: سقوط حر (تسارع كلي منخفض) <<<"));
      }
#else
      warnedFreeFall = true;
#endif
    }
  } else {
    freeFallStartMs = 0;
    if (inFreeFall && mag > IMPACT_G_THRESHOLD) {
#if !SERIAL_PLOTTER_OUTPUT
      Serial.println(F(">>> ارتطام قوي محتمل <<<"));
#else
      impactShowCount = 12;
#endif
    }
    inFreeFall = false;
    warnedFreeFall = false;
  }

#if SERIAL_PLOTTER_OUTPUT
  static uint32_t lastPlot = 0;
  if (now - lastPlot >= PLOT_INTERVAL_MS) {
    lastPlot = now;
    const int ff = inFreeFall ? 1 : 0;
    const int imp = (impactShowCount > 0) ? 1 : 0;
    if (impactShowCount > 0) impactShowCount--;
    char line[128];
    snprintf(line, sizeof(line),
             "%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%.4f,%d,%d",
             ax, ay, az, gx, gy, gz, mag, ff, imp);
    Serial.println(line);
  }
  delay(5);
#else
  static uint32_t lastPrint = 0;
  if (now - lastPrint >= PRINT_INTERVAL_MS) {
    lastPrint = now;

    char buf[96];

    Serial.println(F(" ------------------------------------------------------------"));
    Serial.print(F(" الوقت من التشغيل (ms): "));
    Serial.println(now);

    Serial.println(F(" [1] التسارع الخطي -- الوحدة: g"));
    snprintf(buf, sizeof(buf), "      X = %7.3f    Y = %7.3f    Z = %7.3f", ax, ay, az);
    Serial.println(buf);

    Serial.println(F(" [2] الجيروسكوب -- الوحدة: درجة لكل ثانية"));
    snprintf(buf, sizeof(buf), "      X = %7.1f    Y = %7.1f    Z = %7.1f", gx, gy, gz);
    Serial.println(buf);

    Serial.print(F(" [3] مقدار التسارع الكلي sqrt(x*x+y*y+z*z) = "));
    Serial.print(mag, 3);
    Serial.print(F(" g"));
    if (inFreeFall) Serial.print(F("    تنبيه: سقوط حر؟"));
    Serial.println();

    Serial.println(F(" ------------------------------------------------------------"));
    Serial.println();
  }
  delay(100);
#endif
}
