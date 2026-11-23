# Pediatric Health Monitoring System (IoT + Mobile App)

## 📌 Project Overview
An integrated IoT-based healthcare system designed for continuous monitoring of children's vital signs. The system collects real-time data (Heart Rate, SpO2, Body Temperature, and Foot Pressure) using an ESP32 microcontroller and multiple sensors, and transmits it wirelessly to a cross-platform mobile application built with Flutter.

## 🚀 Key Features
*   **Real-time Monitoring:** Displays live vital signs (Heart Rate, SpO2, Temperature) and foot pressure data.
*   **Data Visualization:** Utilizes `fl_chart` to render interactive charts for tracking health trends over time.
*   **Early Warning System:** Analyzes foot pressure profiles to detect abnormalities and provide early medical alerts.
*   **Report Generation:** Allows users to generate and export comprehensive health reports as PDF files using the `pdf` and `printing` packages.
*   **State Management:** Built with `provider` for efficient and scalable state management.
*   **Data Persistence:** Uses `shared_preferences` to save user settings and preferences locally.
*   **Cross-Platform:** The mobile app is designed to run on Android, iOS, and Web.

## 🛠️ Tech Stack & Hardware
*   **Mobile App:** Flutter (Dart)
*   **Hardware/Firmware:** ESP32 Microcontroller, MAX30105 (SpO2/HR), LM35 (Temperature), MPU6050 (Motion), FSR (Foot Pressure).
*   **Libraries Used:** `http`, `provider`, `fl_chart`, `google_fonts`, `pdf`, `printing`, `shared_preferences`.

## 📂 Repository Structure
*   `/lib`: Contains the main Flutter application code (Screens, Models, Services, State).
*   `/esp32_firmware`: Contains the C++ code for the ESP32 microcontroller.
*   `/android` & `/ios` & `/web`: Platform-specific configurations.

## 👩‍💻 Author
**Rawan Said Rafka** - Information Engineering Graduate
