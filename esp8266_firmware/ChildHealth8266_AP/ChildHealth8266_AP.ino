/*
 * ChildHealth — ESP8266 (D1 mini) + MAX30100 + وضع AP
 * مكتبة: oxullo Arduino-MAX30100 (PulseOximeter)
 *
 * إعدادات مُحسَّنة للقراءة:
 * - أقصى تيار IR معقول (50mA) لإشارة أوضح عند ضعف التماس أو إضاءة المحيط
 * - المكتبة تضبط تلقائياً: SpO2+HR، 100Hz، عرض نبضة 1600µs، وميزان تيار الأحمر تلقائياً
 *
 * السيريال: يطبع الأهم — معدل النبض + الأكسجة SpO2 — كل ~400ms
 */

#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <Wire.h>
#include <ArduinoJson.h>

#include <MAX30100.h>
#include <MAX30100_PulseOximeter.h>

// (اختياري) حرارة — MAX30100 لا يقيس حرارة الجسم بدقة سريرية بدون معايرة
#include <OneWire.h>
#include <DallasTemperature.h>

// ---------------- WiFi AP ----------------
static const char* AP_SSID = "ChildHealth_AP";
static const char* AP_PASS = "12345678";

ESP8266WebServer server(80);

// ---------------- Sensor ----------------
PulseOximeter pox;

static const uint8_t I2C_SDA = D2;
static const uint8_t I2C_SCL = D1;

// DS18B20
static const bool USE_DS18B20 = false;
static const uint8_t ONE_WIRE_PIN = D5;
OneWire oneWire(ONE_WIRE_PIN);
DallasTemperature ds18b20(&oneWire);

// فلترة عرض/JSON






















float hrFiltered = NAN;
float spo2Filtered = NAN;
static const float EMA_HR = 0.22f;
static const float EMA_SPO2 = 0.18f;
static const float HR_MIN = 45.f;
static const float HR_MAX = 190.f;
static const float HR_MAX_STEP = 25.f;

static uint32_t seq = 0;
static uint32_t lastSerialMs = 0;
static uint32_t lastBeatMs = 0;

// طباعة "نبضة" عند كل beat (1 = يزيد الضوضاء على السيريال)
#define SERIAL_BEAT_ECHO 0

// سطر ثاني اختياري بالقيم الخام (0 = إيقاف — الأهم السطر الأول فقط)
#define SERIAL_SHOW_RAW_LINE 0

// إذا 1: تطبع المكتبة R:IR,RED بكل عينة (~100/s) — تغلقها عادة لأنها تملأ السيريال وتبطئ الـHTTP
#define SERIAL_RAW_LIBRARY_DEBUG 0

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

static bool okp(float v) {
  return isfinite(v) && v > 0.f;
}

static float ema(float p, float x, float a) {
  return !isfinite(p) ? x : p + a * (x - p);
}

static float sanitizeHR(float raw) {
  if (!isfinite(raw)) return NAN;
  if (raw < HR_MIN || raw > 240.f) return NAN;
  raw = clampf(raw, HR_MIN, HR_MAX);
  if (!isfinite(hrFiltered)) return raw;
  if (fabs(raw - hrFiltered) > HR_MAX_STEP) {
    raw = hrFiltered + (raw > hrFiltered ? HR_MAX_STEP : -HR_MAX_STEP);
  }
  return raw;
}

static float sanitizeSpO2(float raw) {
  if (!isfinite(raw)) return NAN;
  if (raw < 50.f || raw > 100.f) return NAN;
  return clampf(raw, 80.f, 100.f);
}

static float readTempC() {
  if (!USE_DS18B20) return 36.7f;
  ds18b20.requestTemperatures();
  float t = ds18b20.getTempCByIndex(0);
  if (!isfinite(t) || t < 25.f || t > 45.f) return 36.7f;
  return t;
}

static const char* computeStatus(float spo2, float bpm, float tempC) {
  if (!isfinite(spo2) || !isfinite(bpm) || !isfinite(tempC)) return "watch";
  if (spo2 < 92.f || tempC >= 38.5f || bpm > 150.f || bpm < 55.f) return "alert";
  if (spo2 < 95.f || tempC >= 37.6f || bpm > 130.f || bpm < 60.f) return "watch";
  return "ok";
}

void onBeatDetected() {
  lastBeatMs = millis();
#if SERIAL_BEAT_ECHO
  Serial.println(F("♥ beat"));
#endif
}

void applyMax30100BestEffortSettings() {
  /*
   * بعد begin(): ثبّت أقوى تيار IR ضمن enum المكتبة.
   * القيم الشائعة: MAX30100_LED_CURR_27_1MA … MAX30100_LED_CURR_50MA
   * إذا الإشارة مشبعة (قيم IR عالية جداً وتتذبذب) جرّب خفضها إلى 37mA أو 27mA.
   */
  pox.setIRLedCurrent(MAX30100_LED_CURR_50MA);
}

void noCacheHeaders() {
  server.sendHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
  server.sendHeader("Pragma", "no-cache");
  server.sendHeader("Expires", "0");
  server.sendHeader("Connection", "close");
}

void handleRoot() {
  noCacheHeaders();
  server.send(200, "text/plain; charset=utf-8", "OK. GET /vitals\n");
}

void handleVitals() {
  seq++;
  noCacheHeaders();
  float hrRaw = pox.getHeartRate();
  float spRaw = (float)pox.getSpO2();
  float tempC = readTempC();

  float hr = sanitizeHR(hrRaw);
  float sp = sanitizeSpO2(spRaw);
  if (isfinite(hr)) hrFiltered = ema(hrFiltered, hr, EMA_HR);
  if (isfinite(sp)) spo2Filtered = ema(spo2Filtered, sp, EMA_SPO2);

  float hrOut = okp(hrFiltered) ? hrFiltered : 0.f;
  float spOut = okp(spo2Filtered) ? spo2Filtered : 0.f;

  const char* st = computeStatus(spOut, hrOut, tempC);

  StaticJsonDocument<384> doc;
  doc["spo2"] = spOut;
  doc["bpm"] = (int)lroundf(hrOut);
  doc["temp_c"] = tempC;
  doc["status"] = st;
  doc["rssi"] = WiFi.RSSI();
  doc["device"] = "d1_mini_max30100";
  doc["seq"] = seq;
  doc["uptime_ms"] = millis();
  doc["hr_raw"] = hrRaw;
  doc["spo2_raw"] = spRaw;
  doc["red_led_idx"] = pox.getRedLedCurrentBias();

  String body;
  serializeJson(doc, body);
  server.send(200, "application/json; charset=utf-8", body);
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println();
  Serial.println(F("=== ChildHealth8266 AP / MAX30100 ==="));

  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000);

  if (USE_DS18B20) {
    ds18b20.begin();
  }

  Serial.println(F("Init MAX30100 + PulseOximeter..."));
#if SERIAL_RAW_LIBRARY_DEBUG
  bool ok = pox.begin(PULSEOXIMETER_DEBUGGINGMODE_RAW_VALUES);
#else
  bool ok = pox.begin(PULSEOXIMETER_DEBUGGINGMODE_NONE);
#endif
  if (!ok) {
    Serial.println(F("FAIL: تحقق من التوصيل I2C (SDA=D2, SCL=D1) و3.3V."));
    while (true) {
      delay(1000);
    }
  }

  applyMax30100BestEffortSettings();
  pox.setOnBeatDetectedCallback(onBeatDetected);

  Serial.println(F("Sensor OK. IR LED = 50mA (عدّل في الكود إذا لزم)."));
  Serial.println(F("ضع الإصبع بثبات يغطي الحساس بالكامل؛ تجنب الضوء الساطع المباشر."));
  Serial.println(F("--- السيريال: يعرض «نبض القلب» و «الأكسجة SpO2» ---"));

  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.print(F("AP SSID: "));
  Serial.println(AP_SSID);
  Serial.print(F("AP IP:   "));
  Serial.println(WiFi.softAPIP());

  server.on("/", HTTP_GET, handleRoot);
  server.on("/vitals", HTTP_GET, handleVitals);
  server.onNotFound([]() {
    noCacheHeaders();
    server.send(404, "text/plain", "Not found");
  });
  server.begin();
  Serial.println(F("HTTP server started."));
}

void loop() {
  server.handleClient();
  pox.update();

  uint32_t now = millis();
  if (now - lastSerialMs >= 400) {
    lastSerialMs = now;

    float hrRaw = pox.getHeartRate();
    uint8_t spRaw8 = pox.getSpO2();
    float spRaw = (float)spRaw8;

    float hr = sanitizeHR(hrRaw);
    float sp = sanitizeSpO2(spRaw);
    if (isfinite(hr)) hrFiltered = ema(hrFiltered, hr, EMA_HR);
    if (isfinite(sp)) spo2Filtered = ema(spo2Filtered, sp, EMA_SPO2);

    float hrOut = okp(hrFiltered) ? hrFiltered : 0.f;
    float spOut = okp(spo2Filtered) ? spo2Filtered : 0.f;

    // السطر الأساسي: النبض + الأكسجة (الأهم)
    if (hrOut > 0.f && spOut > 0.f) {
      Serial.printf("نبض القلب: %.0f نبضة/دقيقة  |  الأكسجة SpO2: %.0f %%\n", hrOut, spOut);
    } else if (hrOut > 0.f) {
      Serial.printf("نبض القلب: %.0f نبضة/دقيقة  |  الأكسجة SpO2: --\n", hrOut);
    } else if (spOut > 0.f) {
      Serial.printf("نبض القلب: --  |  الأكسجة SpO2: %.0f %%\n", spOut);
    } else {
      Serial.println(F("نبض القلب: --  |  الأكسجة SpO2: --   (ثبّت الإصبع على الحساس)"));
    }

#if SERIAL_SHOW_RAW_LINE
    Serial.printf("  (خام: نبض=%.1f  SpO2=%u  redLEDidx=%u)\n", hrRaw, (unsigned)spRaw8, (unsigned)pox.getRedLedCurrentBias());
#endif
  }
}
