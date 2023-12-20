

#include "Firebase_Arduino_WiFiNINA.h"

#define DATABASE_URL "bus-semester-5-default-rtdb.firebaseio.com" //<databaseName>.firebaseio.com or <databaseName>.<region>.firebasedatabase.app
#define DATABASE_SECRET "yH6CDkCOHcoiZE91MiBJkCDgF1Nea5SaCAXBPQyi"
#define WIFI_SSID "DuoiNha95"
#define WIFI_PASSWORD "95959595"

//Define Firebase data object
FirebaseData fbdo;

#include "thingProperties.h"
#include <Wire.h>
#include <Arduino_MKRIoTCarrier.h>
MKRIoTCarrier carrier;


const int maxPeople = 4;
const int LED = A1;
const int baseTemp = 23;
bool personIn = false;
bool personOut = false;
// Define the pins for the first ultrasonic sensor

const int trigPin1 = 4;
const int echoPin1 = 0;
// Define the pins for the second ultrasonic sensor

const int trigPin2 = 5;
const int echoPin2 = 1;
unsigned long entryTime1 = ULONG_MAX;
unsigned long entryTime2 = ULONG_MAX;
bool switch_RGB;
int brightness;

void setup() {
  
  // Initialize serial and wait for port to open:
  Serial.begin(9600);
  // This delay gives the chance to wait for a Serial Monitor without blocking if none is found
  delay(1500); 
  // connect firebase
  Firebase.begin(DATABASE_URL, DATABASE_SECRET, WIFI_SSID, WIFI_PASSWORD);
  Firebase.reconnectWiFi(true);
 
  Wire.begin(); // join i2c bus
  // Defined in thingProperties.h
  initProperties();
  // Connect to Arduino IoT Cloud
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  setDebugMessageLevel(2);
  ArduinoCloud.printDebugInfo();
  //Wait to get cloud connection to init the carrier
  while (ArduinoCloud.connected() != 1) {
    ArduinoCloud.update();
    delay(500);
  }
  delay(500);
  CARRIER_CASE = false;
  carrier.begin();
  carrier.display.setRotation(0);
  delay(1500);
  pinMode(trigPin1, OUTPUT);
  pinMode(trigPin2, OUTPUT);
  // Set the echo pins as inputs
  pinMode(echoPin1, INPUT);
  pinMode(echoPin2, INPUT);
  pinMode(LED, OUTPUT); // Set pin LED as an output
  digitalWrite(LED, LOW); 
  // peopleCount = 0;
  
}

void loop() {

  ArduinoCloud.update();
  temperature = carrier.Env.readTemperature();
  Serial.println(temperature);
  
  humidity = carrier.Env.readHumidity();
  
  Serial.println(humidity);
  
  // Measure distance for the first sensor
  
  digitalWrite(trigPin1, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin1, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin1, LOW);
  long duration1 = pulseIn(echoPin1, HIGH);
  int distance1 = duration1 / 58;
  
  // Measure distance for the second sensor
  
  digitalWrite(trigPin2, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin2, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin2, LOW);
  long duration2 = pulseIn(echoPin2, HIGH);
  int distance2 = duration2 / 58;
  
  // Print the distances to the serial monitor
  
  Serial.print("Distance 1: ");
  Serial.print(distance1);
  Serial.print(" cm, Distance 2: ");
  Serial.print(distance2);
  Serial.println(" cm");
  
  
  
  // Check if a person is entering or leaving room
  if (!personIn){
    if (distance1 < 10) {
      entryTime1 = millis();
      personIn = true;
    } 
  }

  if (!personOut ){
    if (distance2 < 10) {
      entryTime2 = millis();
      personOut = true;
    } 
  }
  
  if (entryTime1 < ULONG_MAX && entryTime2 < ULONG_MAX ) {
    if (entryTime1 < entryTime2){
     if (peopleCount < maxPeople){
        peopleCount++;
     }
  }
  
    if (entryTime1 > entryTime2){
      if (peopleCount >0){
        peopleCount--;
     }
    }
    entryTime1 = ULONG_MAX;
    entryTime2 = ULONG_MAX;
    personIn = false;
    personOut = false;
  } 
  
  
  Serial.print("People Count: ");
  
  Serial.println(peopleCount);
  
  
  if(peopleCount == maxPeople){
    digitalWrite(LED, HIGH);
    full = true;
  }
  else {
    digitalWrite(LED, LOW);
    full = false;
  }
  
  
  updatePeopleCount();
  updatePeopleCountFirebase();
  
  updateTemperatureAndHumidity();
  

  uint8_t r, g, b;
  control_RGB.getValue().getRGB(r, g, b);
  brightness = dim.getBrightness();
  switch_RGB = dim.getSwitch();
  if ( switch_RGB) {
    lightOn(r, g, b, brightness);
  } else {
    lightsOff();
  }
  
  delay(1000);
}

void lightOn(uint8_t r, uint8_t g, uint8_t b, uint8_t brightness) {

 carrier.leds.setPixelColor(0, g * brightness / 255, r * brightness / 255, b * brightness / 255);
 carrier.leds.setPixelColor(1, g * brightness / 255, r * brightness / 255, b * brightness / 255);
 carrier.leds.setPixelColor(2, g * brightness / 255, r * brightness / 255, b * brightness / 255);
 carrier.leds.setPixelColor(3, g * brightness / 255, r * brightness / 255, b * brightness / 255);
 carrier.leds.setPixelColor(4, g * brightness / 255, r * brightness / 255, b * brightness / 255);
 carrier.leds.show();

}


void lightsOff() {

  carrier.leds.setPixelColor(0, 0, 0, 0);
  carrier.leds.setPixelColor(1, 0, 0, 0);
  carrier.leds.setPixelColor(2, 0, 0, 0);
  carrier.leds.setPixelColor(3, 0, 0, 0);
  carrier.leds.setPixelColor(4, 0, 0, 0);
  carrier.leds.show();

}



void updatePeopleCount() {

  Wire.beginTransmission(4); // transmit to device #4
  
  Wire.write(peopleCount);
  
  Wire.endTransmission(); // stop transmitting

}

void updatePeopleCountFirebase() {
    String pathPeople = "/Occupancy"; // Firebase path for people count
    String pathFull = "/Room_Full";

    // Push the people count to the Firebase database
    if (Firebase.setInt(fbdo, pathPeople, peopleCount)) {
        Serial.println("People count updated successfully");
    } else {
        Serial.println("Error updating people count: " + fbdo.errorReason());
    }
    
    // Push the full status to the Firebase database
    if (Firebase.setInt(fbdo, pathFull, full)) {
        Serial.println("People count updated successfully");
    } else {
        Serial.println("Error updating full: " + fbdo.errorReason());
    }
}

void updateTemperatureAndHumidity() {
    String pathTemp = "/temperature"; // Firebase path for temperature
    String pathHumidity = "/humidity"; // Firebase path for humidity

    // Push temperature to the Firebase database
    if (Firebase.setFloat(fbdo, pathTemp, temperature)) {
        Serial.println("Temperature updated successfully");
    } else {
        Serial.println("Error updating temperature: " + fbdo.errorReason());
    }

    // Push humidity to the Firebase database
    if (Firebase.setFloat(fbdo, pathHumidity, humidity)) {
        Serial.println("Humidity updated successfully");
    } else {
        Serial.println("Error updating humidity: " + fbdo.errorReason());
    }
}


void onTemperatureChange() {

 // Add your code here to act upon Temperature change

}
void onHumidityChange() {

 // Add your code here to act upon Temperature change

}

void onPeopleCountChange() {

 // Add your code here to act upon PeopleCount change

}

void onFullChange() {

 // Add your code here to act upon Full change

}

void onControlRGBChange() {

 // Add your code here to act upon ControlRGB change

}

void onDimChange() {

 // Add your code here to act upon Dim change

}



