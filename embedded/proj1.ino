#include <Arduino.h>

// ESP Now requirements
#include <WiFi.h>
#include <esp_now.h>

// BLE requirements
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// Hardware variable declarations
#define SOIL_MOISTURE_PIN 0
#define LDR_PIN 1

// =================================== BLE Server Configuration =========================================
// BLE Identifications 
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define MOISTURE_CHAR_ID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define LIGHT_CHAR_ID "4af306e2-2e5e-40b3-b448-f9937ba4557a"

BLECharacteristic *moistureCharacteristic;
BLECharacteristic *lightCharacteristic;
BLEService *pService;

void setupBLE()
{
  BLEServer *pServer = BLEDevice::createServer();
  pService = pServer->createService(SERVICE_UUID);
  moistureCharacteristic = pService->createCharacteristic(
    MOISTURE_CHAR_ID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  lightCharacteristic = pService->createCharacteristic(
    LIGHT_CHAR_ID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // fix iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("Characteristic defined! Now you can read it in your phone!");
}

// ==================================== ESP NOW CONFIGURATION ===========================================
// ESP Now receiver MAC Addresses
enum MessageType {PAIRING, DATA,};
// MessageType messageType;
int counter = 0;

typedef struct struct_pairing {       // new structure for pairing
    uint8_t msgType;
    uint8_t id;
    uint8_t macAddr[6];
    uint8_t channel;
} struct_pairing;

// Data structure that will be sent within the ESP Now network
typedef struct struct_message {
  double soilMoisture;
  double ldr;
} struct_message;

// Generate data
struct_message myData;

// ESP Now peer information
esp_now_peer_info_t peerInfo;

// ESP Now callback when the data has been sent successfully
void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
}

// // ESP Now callback when receiving data from the network
void OnDataReceived(const uint8_t * mac, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  Serial.print("Data received: ");
  Serial.println(len);
  Serial.print("Moisture level: ");
  Serial.println(myData.soilMoisture);
  Serial.print("Light level: ");
  Serial.println(myData.ldr);
  Serial.println();
}

// void setupEspNow()
// {
//   WiFi.mode(WIFI_MODE_STA);

//   if (esp_now_init() != ESP_OK) {
//     Serial.println("Error initializing ESP-NOW");
//     return;
//   }

//   esp_now_register_send_cb(OnDataSent);
//   esp_now_register_recv_cb(OnDataReceived);

//   // Register peer
//   memcpy(peerInfo.peer_addr, broadcastAddress, 6);
//   peerInfo.channel = 0;
//   peerInfo.encrypt = false;

//   // Add peer
//   if (esp_now_add_peer(&peerInfo) != ESP_OK) {
//     Serial.println("Failed to add peer");
//     return;
//   }
// }

// void onEspNowAction()
// {
//   for (int i = 0; i < 5; i++) {
//     esp_err_t result = esp_now_send(broadcastAddress[i], (uint8_t *) &myData, sizeof(myData));

//     if (result == ESP_OK) {
//       Serial.println("Sending confirmed");
//     } else {
//       Serial.println("Sending error");
//     }
//   }
// }

// ================================= MAIN PROGRAM =====================================

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  // Create the BLE Device
  BLEDevice::init("SPC_zero_white");

  // Init setup
  setupBLE();
  // setupEspNow();
}

void loop() {
  Serial.println("Fetching sensor data");
  double moistureValue = analogRead(SOIL_MOISTURE_PIN);
  double ldrValue = analogRead(LDR_PIN);
  // myData.soilMoisture = moisture;
  // myData.ldr = ldr;
  // double moistureValue = random(100, 1000);
  // double ldrValue = random(100, 500);

  char moisture[8];
  char light[8];
  sprintf(moisture, "%.2f", moistureValue);
  sprintf(light, "%.2f", ldrValue);

  Serial.println("light: " + String(ldrValue));
  Serial.println("moisture: " + String(moistureValue));

  moistureCharacteristic->setValue(moisture);
  lightCharacteristic->setValue(light);

  moistureCharacteristic->notify();
  lightCharacteristic->notify();

  delay(3000);
}
