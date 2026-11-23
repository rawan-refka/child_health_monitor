/*
 * خادم HTTP لـ ESP32 — GET /vitals يعيد JSON للتطبيق (بدون مكتبات JSON خارجية)
 * عيّن SSID وكلمة المرور، ثم اطبع IP في Serial وأدخلها في إعدادات تطبيق Flutter.
 */

#include <WiFi.h>
#include <WebServer.h>

static const char* WIFI_SSID = "YOUR_WIFI_SSID";
static const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";

WebServer server(80);

static float lastSpO2 = 98.0f;
static int lastBpm = 92;
static float lastTempC = 36.7f;

void setup() {
  Serial.begin(115200);
  delay(300);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  server.on("/vitals", HTTP_GET, handleVitals);
  server.onNotFound([]() { server.send(404, "text/plain", "Not found"); });
  server.begin();
}

void loop() {
  server.handleClient();
  pollSensors();
  delay(5);
}

void pollSensors() {
  // اربط حساساتك هنا (SpO2، نبض، حرارة).
}

void handleVitals() {
  pollSensors();

  const char* status = "ok";
  if (lastSpO2 < 92.0f || lastTempC >= 38.5f) {
    status = "alert";
  } else if (lastSpO2 < 95.0f || lastTempC >= 37.6f) {
    status = "watch";
  }

  char body[400];
  snprintf(
      body,
      sizeof(body),
      "{\"spo2\":%.1f,\"bpm\":%d,\"temp_c\":%.2f,\"status\":\"%s\",\"rssi\":%d,"
      "\"device\":\"esp32_child_unit\",\"ts\":%lu}",
      lastSpO2,
      lastBpm,
      lastTempC,
      status,
      WiFi.RSSI(),
      (unsigned long)millis());

  server.send(200, "application/json; charset=utf-8", body);
}
