import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;

ControlIO control;
ControlDevice gamepad;
ControlSlider x, y, rot;

// 1 pixel * scale = 1 millimeter
// angles are in radians,
// increasing counterclockwise,
// with right being 0
final float scale = 1 / 2.5;
final float trackWidth = 350;

float leftAngle, rightAngle;

float iX, iY, iRot;
PVector inputVec;

int readoutCount;

float in2mm(float in) {
  return 25.4 * in;
}

float mm2in(float mm) {
  return mm / 25.4;
}

void setup() {
  size(700, 700);
  leftAngle = 0.5 * PI;
  rightAngle = 0.5 * PI;
  inputVec = new PVector();
  control = ControlIO.getInstance(this);
  try {
    gamepad = control.getDevice("Controller (Gamepad F310)");
  } catch (RuntimeException e) {
    println("No controller found. Exiting.");
    exit();
    return;
  }
  x = gamepad.getSlider("X Rotation");
  y = gamepad.getSlider("Y Rotation");
  rot = gamepad.getSlider("X Axis");
  rot.setTolerance(0.1);
}

void draw() {
  float rawMag = sqrt(sq(x.getValue()) + sq(-y.getValue()));
  float rawRot = rot.getValue();
  iX = 200 * x.getValue();
  iY = 200 * -y.getValue();
  iRot = map(rot.getValue(), -1, 1, -QUARTER_PI, QUARTER_PI);
  readoutCount = 0;
  background(0);
  fill(255);
  
  readout("Raw Mag", rawMag);
  readout("Raw Rot", rawRot);

  /*float mX = mouseX - (width / 2.0);
  if (mousePressed) {
    iRot = constrain(map(mX, -200, 200, -QUARTER_PI, QUARTER_PI), -QUARTER_PI, QUARTER_PI);
  } else {
    iX = mX;
    iY = -(mouseY - (height / 2.0));
    iRot = 0;
  }*/
  inputVec.set(iX, iY);
  inputVec.div(scale);

  leftAngle = rightAngle = inputVec.heading();

  float mag = inputVec.mag();
  float chord = mag / sin(HALF_PI - iRot);
  float arcAngle = 2.0 * iRot;
  //float arcRadius = (chord) / (2.0 * sin(arcAngle));
  float arcRadius = chord / (2.0 * sin(arcAngle / 2.0));
  readout("Heading", inputVec.heading());
  readout("Arc Radius", arcRadius);
  readout("Chord", chord);
  readout("Arc Angle", arcAngle);
  readout("X", iX);
  readout("Y", iY);
  readout("R", iRot);

  PVector leftPos = new PVector(-0.5 * trackWidth, 0);
  PVector rightPos = new PVector(0.5 * trackWidth, 0);
  leftPos.rotate(inputVec.heading() - HALF_PI);
  rightPos.rotate(inputVec.heading() - HALF_PI);

  PVector arcPosition = new PVector(arcRadius, 0);
  PVector toLeft = PVector.sub(leftPos, arcPosition);
  PVector toRight = PVector.sub(rightPos, arcPosition);
  
  if (iRot != 0) {
    leftAngle = -toLeft.heading() - (HALF_PI - inputVec.heading());
    rightAngle = -toRight.heading() - (HALF_PI - inputVec.heading());
    if (iRot > 0) {
      leftAngle -= HALF_PI;
      rightAngle -= HALF_PI;
    } else {
      leftAngle += HALF_PI;
      rightAngle += HALF_PI;
    }
  }
  
  float leftRadius = toLeft.mag();
  float rightRadius = toRight.mag();
  float leftArcLength = abs(leftRadius * arcAngle);
  float rightArcLength = abs(rightRadius * arcAngle);
  
  float maxArcLength = max(leftArcLength, rightArcLength);
  float leftSpeed = leftArcLength / maxArcLength;
  float rightSpeed = rightArcLength / maxArcLength;
  
  float inputSpeed = constrain(rawMag + abs(rawRot), 0, 1);
  leftSpeed *= inputSpeed;
  rightSpeed *= inputSpeed;
  
  if (iRot == 0) {
    leftSpeed = rightSpeed = rawMag;
  }
  
  readout("Left Arc Length", leftArcLength);
  readout("Right Arc Length", rightArcLength);
  readout("Left Speed", leftSpeed);
  readout("Right Speed", rightSpeed);

  readout("Left Pos X", leftPos.x);
  readout("Left Pos Y", leftPos.y);

  noFill();
  stroke(255);
  rectMode(CENTER);
  ellipseMode(RADIUS);

  translate(width / 2.0, height / 2.0);
  scale(scale);

  rect(0, 0, in2mm(18), in2mm(18));

  {
    float xOff = 0.5 * trackWidth;
    float casterRadius = 0.5 * (in2mm(4) + 30);
    ellipse(-xOff, 0, casterRadius, casterRadius);
    ellipse(xOff, 0, casterRadius, casterRadius);

    pushMatrix();
    translate(-xOff, 0);
    rotate(-(leftAngle + HALF_PI));
    rect(0, 0, in2mm(1), in2mm(4));
    line(in2mm(-0.5), 30, 0, in2mm(2));
    line(in2mm(0.5), 30, 0, in2mm(2));
    popMatrix();

    pushMatrix();
    translate(xOff, 0);
    rotate(-(rightAngle + HALF_PI));
    rect(0, 0, in2mm(1), in2mm(4));
    line(in2mm(-0.5), 30, 0, in2mm(2));
    line(in2mm(0.5), 30, 0, in2mm(2));
    popMatrix();
  }

  {
    pushMatrix();
    rotate(HALF_PI - inputVec.heading());
    if (iRot == 0) {
      line(0, 0, 0, -mag);
    }
    //line(0, 0, leftPos.x, leftPos.y);
    //line(0, 0, rightPos.x, rightPos.y);
    /*if (iRot != 0) {
      line(arcRadius, 0, leftPos.x, leftPos.y);
      line(arcRadius, 0, rightPos.x, rightPos.y);
    }*/
    float arcStart, arcStop;
    if (iRot > 0) {
      arcStart = PI;
      arcStop = PI + arcAngle;
    } else {
      arcStart = TWO_PI + arcAngle;
      arcStop = TWO_PI;
    }
    arc(arcRadius, 0, abs(arcRadius), abs(arcRadius), arcStart, arcStop);
    arc(arcRadius, 0, toLeft.mag(), toLeft.mag(), arcStart, arcStop);
    arc(arcRadius, 0, toRight.mag(), toRight.mag(), arcStart, arcStop);
    datum();
    rotate(iRot);
    //line(0, 0, 0, -chord); 
    popMatrix();
  }
}

void datum() {
  pushStyle();
  noFill();
  stroke(255, 0, 0);
  line(0, 0, 50, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 50);
  popStyle();
}

void readout(String name, float val) {
  pushMatrix();
  resetMatrix();
  text(name + ": " + nf(val), 10, 20 * (readoutCount + 1));
  popMatrix();
  readoutCount++;
}
