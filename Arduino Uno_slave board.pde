
#include <LiquidCrystal.h>
#include <Wire.h>

// LCD Configuration
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

void setup() {
  Wire.begin(4); // Initialize and join I2C bus with address #4
  Wire.onReceive(receiveEvent); // Register the receiveEvent function to handle I2C 

  Serial.begin(9600);
// display on LCD
  lcd.begin(16, 2);
  lcd.print("People Count: ");
  // lcd.setCursor(0, 1);
  // lcd.print(peopleCount);
}

void loop() {
  delay(1000);
}

void receiveEvent(int howMany) {
 int peopleCount = Wire.read(); // Read the received byte as an integer
 Serial.println(peopleCount); // Print the integer to the serial monitor
 // Update LCD with People Count
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("People Count: ");
  lcd.setCursor(0, 1);
  lcd.print(peopleCount);
  delay(500);
}
