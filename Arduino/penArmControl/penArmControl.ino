#include <Scheduler.h>

const String _version = "2.1.1";

#define BRAKE 0
#define STILL 0
#define CW   1
#define CCW  2


//pin setup for motorshield
int direc[2] = {12, 13}; // Direction
int pwmpin[2] = {3, 11}; // PWM input
int cspin[2] = {0, 1}; // CS: Current sense ANALOG input
int brake[2] = {9, 8};

//pin setup for encoder
const int Apin = 22;
const int Bpin = 23;
const int Indpin = 24;

//encoder const setup
const int radius = 50+1.5; //[mm]
const double stepDis = 2.0/160.0;
const double stepAng = (stepDis/radius)*180.0/PI;

//global var
volatile double angle = 0.0;
volatile double preAngle = 0.0;
volatile double lastoutAngle = 0.0;
double delta_ang = 0.5; // should be less than 0.5
// pen direction
volatile int penDirection = STILL;
volatile int prePenDirection = STILL;
volatile bool penInOneArc = false;

//current sensor
const float volt_per_amp = 1.65;
float currentRaw; // the raw analogRead ranging from 0-1023
float currentVolts; // raw reading changed to Volts
float currentAmps; // Voltage reading changed to Amps

char instruction = 0;



// encoder parameter 
double minAngle = 0.0;
double maxAngle = 0.0;
double targetAngle = 90.0;

// pen parameter
bool penReady = false;
const double fireAngle = 0.20;
const uint8_t firePower = 255;


//switches
bool penOn = false;
bool angleOut = false;
bool angleOutPassive = false;

bool debug = false;

void setup() {
  // put your setup code here, to run once:
  //start serial connection
  Serial.begin(250000);
  //pin setup
  pinMode(Apin, INPUT);
  pinMode(Bpin, INPUT);
  pinMode(Indpin, INPUT);
  attachInterrupt(digitalPinToInterrupt(Apin), APulse, CHANGE);
  attachInterrupt(digitalPinToInterrupt(Bpin), BPulse, CHANGE);
  attachInterrupt(digitalPinToInterrupt(Indpin), IndpinPulse, RISING);

  for (int i=0; i<2; i++)
  {
    pinMode(direc[i], OUTPUT);
    pinMode(brake[i], OUTPUT);
    pinMode(pwmpin[i], OUTPUT);
  }
  
  // Initialize braked
  for (int i=0; i<2; i++)
  {
    digitalWrite(brake[i], HIGH);
  }
  
  // Add "pendulum" and "encoder" to scheduling.
  // "loop" is always started by default.
  Scheduler.startLoop(pendulum);
  Scheduler.startLoop(encoder);
  
}//setup

void APulse(){
  if (digitalRead(Apin) == digitalRead(Bpin)){
    angle += stepAng;
  }
  else{
    angle -= stepAng;
  } 
}

void BPulse(){
  if (digitalRead(Apin) == digitalRead(Bpin)){
    angle -= stepAng;
  }
  else{
    angle += stepAng; 
  }
}

void IndpinPulse(){
  if (digitalRead(Apin) == LOW && digitalRead(Bpin)== LOW && digitalRead(Indpin) == HIGH){
    Serial.println("Error!! No Magnet Ring!!!");
    //angle = 0;
    //preAngle = 0;
  }
}


/* motorGo() will set a motor going in a specific direction
 the motor will continue going in that direction, at that speed
 until told to do otherwise.
 
 motor: this should be either 0 or 1, will selet which of the two
 motors to be controlled
 
 direct: Should be between 0 and 3, with the following result
 0: Brake to VCC
 1: Clockwise
 2: CounterClockwise
 
 pwm: should be a value between 0 and 255, higher the number, the faster
 it'll go
 */

void motorGo(uint8_t motor, uint8_t direct, uint8_t pwm){
  if(motor<=1){
    switch(direct){
      case 1:
        digitalWrite(direc[motor],HIGH);
        digitalWrite(brake[motor],LOW);
        analogWrite(pwmpin[motor],pwm);
        break;
      case 2:
        digitalWrite(direc[motor],LOW);
        digitalWrite(brake[motor],LOW);
        analogWrite(pwmpin[motor],pwm);
        break;
      default:
        digitalWrite(brake[motor],HIGH);
    }
  }
}


void loop() {//handle user requests
  instruction = '0';
  
  if(Serial.available()>0){
    instruction = Serial.read();
    //Serial.println(instruction);
    switch(instruction){
      case '1': { // turn on pendulum
        String input = Serial.readString();
        //Serial.println(input.toFloat());
        targetAngle = (double)input.toFloat();
        if(targetAngle > 0){
          //Serial.println("pen on.");
          penOn = true;
          Serial.println("1");
        }
        else{
          //Serial.println("target angle can not be zero please enter it again. 0");
          Serial.println("0");
        }
        break;
      }
      case '2': {// output encoder angle
        String input = Serial.readString();
        //Serial.println("here");
        //Serial.println(input.toFloat());
        delta_ang = (double)input.toFloat();
        if(delta_ang > 0){
          //Serial.println("encoder out on. 1");
          angleOut = true;
          angleOutPassive = false;
          Serial.println("1");
        }
        else{
          //Serial.println("delta_ang can not be zero please enter it again. 0");
          Serial.println("0");
        }
        break;
      }
      case '3': //turn on angleOutPassive
        angleOutPassive = true;
        angleOut = false;
        Serial.println("1");
        break;
      case '4': 
        penOn = false;
        //Serial.println("pen off.");
        Serial.println("1");
        break;
      case '5': 
        angleOut = false;
        angleOutPassive = false;
        //Serial.println("encoder out off.");
        Serial.println("1");
        break;
      case 'i': // output instance angle
        Serial.println(angle,4);
        break;
      case 'r': // check ready or not (i.e. pen reaches target angle)
        Serial.println(penReady);
        break;
      case 's': // return status of opeartions
        if(penOn&&(angleOut||angleOutPassive)){
          Serial.println("1");
        }
        else{
          Serial.println("0");
        }
        break;
      case 'd': // turn debug on off
        if(debug){
          debug = false;
        }
        else{
          debug = true;
        }
        break;
      case 'v':
        Serial.println(_version);
        break;
    }
  }// if serial in 
  
  yield();
}

void pendulum(){//control the movement of the pendulum
  if(penOn){
    if(penDirection == CW && abs(angle-fireAngle)<0.02){ // pen is cw
      motorGo(0, CCW, firePower);
      while(abs(angle)<2.5){yield();}
      //delay(80);
      if(debug){
        Serial.print("CW  Current angle: ");
        Serial.print(angle,4);
        Serial.print("\tMin angle: ");
        Serial.println(minAngle,4);
      }
      motorGo(0, CW, firePower);
      penReady = true;
      if(abs(minAngle)<targetAngle){
        penReady = false;
      }
      minAngle = 0.0; // set min angle to zero
    }
    else if(penDirection == CCW && abs(angle+fireAngle)<0.02){ //pen is ccw
      motorGo(0, CCW, firePower);
      while(abs(angle)<2.3){yield();}
      //delay(80);
      if(debug){
        Serial.print("CCW Current angle: ");
        Serial.print(angle,4);
        Serial.print("\tMax angle: ");
        Serial.println(maxAngle,4);
      }
      motorGo(0, CW, firePower);
      penReady = true;
      if(abs(maxAngle)<targetAngle){
        penReady = false;
      }
      maxAngle = 0.0;
    }
  }
  else{//pen is off
    motorGo(0, BRAKE, firePower); //pen break to VCC
    minAngle = 0.0;
    maxAngle = 0.0;
    penReady = false;
  }

  
  currentRaw = analogRead(cspin[0]);
  currentVolts = currentRaw *(5.0/1024.0);
  currentAmps = currentVolts/volt_per_amp;
  
  if(currentAmps>1.9){
    if(debug){
      Serial.println(currentAmps);
    }
    penOn = false;
    Serial.println("Current exceeds limits, pen off.");
  }

  
  yield();
}

void encoder(){ //control the in/output of encoder
//  Serial.println("here");
//  Serial.print("preAngle: ");
//  Serial.println(preAngle,4);
//  Serial.print("angle: ");
//  Serial.println(angle,4);
//  delay(500);
  
  // update pendirection
  if((preAngle-angle)<0){
    penDirection = CW;
  }
  if((preAngle-angle)>0){
    penDirection = CCW;
  }
//  if(preAngle==angle){
//    penDirection = STILL;
//  }

  // update max min angle
  if(angle<minAngle){
    minAngle = angle;
  }
  if(angle>maxAngle){
    maxAngle = angle;
  }

  //check pendirection changes
  if(prePenDirection != penDirection && penOn && (angleOut||angleOutPassive) && penReady){ //pen truning point
    if(debug){
      Serial.print("penDirection: ");
      Serial.println(penDirection);
      Serial.print("prePenDirection: ");
      Serial.println(prePenDirection);
    }
    if(penDirection==CCW){ // pen was at left most point
      penInOneArc = true;
      Serial.println("start");
    }
    else if(penDirection==CW){ // pen was at right most point
      penInOneArc = false;
      Serial.println("end");
    }
    else{ // pen came to a stop
      penInOneArc = false;
    }
  }

  
  //output angle
  if(penOn && angleOut && penInOneArc && abs(angle-lastoutAngle)>=delta_ang){
    Serial.println(angle,4);
    lastoutAngle = angle;
  }
  
  
  preAngle = angle;
  prePenDirection = penDirection;
  yield();
}


