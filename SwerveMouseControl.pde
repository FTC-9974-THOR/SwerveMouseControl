// Swerve Drive Kinematics
// written by fortraan/FlufferOverflowException of team FTC9974 T.H.O.R.

// the box in the middle represents the robot. the 2 wheels are on the right and left side of the robot, and the arrow denotes which way is "forwards".
// the wheels will turn to match the given movement input. At all times, the desired path of motion is displayed, starting at the center of the robot.
// if there is a turn input, the path the wheels will take is drawn as well.

// the idea behind the kinematics is to calculate the arc that the center of the robot will follow. The radius of this arc is proportional to desired
// movement speed, and is inversely proportional to desired turning speed. At full turning speed, the arc will turn 90 degrees within the simulated
// length. at 0 turning speed, the radius of the arc is infinite, as it is a straight line.
// the kinematics calculates the center point of this arc. from there, it finds the arc that the wheels will transcribe around this point.
// to do this, it finds the displacement vector between that point and each of the wheels. the line of tangency for the transcribed arc is normal to
// the radius line of the arc, so the line of tangency is thus normal to this displacement vector. In simpler terms, it points the wheels at a right
// angle to this displacement vector.
// now the kinematics needs to calculate wheel speeds. the direction of the wheels is not influenced at all by the desired movement speed, as the kinematics
// calculates them by simulating the path of the robot. The only thing that desired movement speed effects is how fast the robot moves along this path.
// the speed of a wheel going through a turn is proportional to the radius of the arc transcribed by the wheel. Since the kinematics knows this radius,
// it's easy to calculate a speed coefficient for each wheel. the outermost wheel will have a coefficient of 1, as it will be moving the fastest. a
// wheel that lies directly on the center of rotation (and thus has a turning radius of 0) will not move at all, and have a coefficient of 0. a wheel
// that lies at 50mm away from the center of the turn will move at half the speed of a wheel that lies at 100mm away.
// given these speed coefficients, the kinematics must mix these with the desired movement speed. This is tricky, as movement speed and turning speed
// are typically completely independent, such as in mecanum kinematics. however, this kinematic model treats movement and turning as the same motion,
// and thus isn't capable of moving at a specific speed (say, 1.5m/s) while turning at a specific speed (i.e., pi/2 rad/s). How the kinematics
// calculates base wheel speed is bascially a heuristic. my implementation calculates wheel speeds as
//
// s_w * (v_m + |v_r|)/2
//
// where s_w is the wheel speed coefficient, v_m is the desired movement speed, and v_r is the desired rotational speed.

// this version of the demo is controlled by the mouse. The robot will drive in a straight line towards the mouse normally. click and hold to freeze
// the current x-y input, and move the mouse perpendicular to the frozen path to do turn input. It's janky, but i'm not really sure how to do 3-axis
// analog input with only 2-axis input from the mouse.

// i wrote this a while ago, as a temporary interim between working the kinematics out on paper and
// actually implementing them on the robot. Hence, there's pretty much no comments, and about 80%
// of this code is GUI awfulness. I apologize in advance for what you're about to read.

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

PVector lastNoTurnInput;

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
  /*try {
    gamepad = control.getDevice("Controller (Gamepad F310)");
  } catch (RuntimeException e) {
    println("No controller found. Exiting.");
    exit();
    return;
  }
  x = gamepad.getSlider("X Rotation");
  y = gamepad.getSlider("Y Rotation");
  rot = gamepad.getSlider("X Axis");
  rot.setTolerance(0.1);*/
}

void draw() {
  /*float rawMag = sqrt(sq(x.getValue()) + sq(-y.getValue()));
  float rawRot = rot.getValue();
  iX = 200 * x.getValue();
  iY = 200 * -y.getValue();
  iRot = map(rot.getValue(), -1, 1, -QUARTER_PI, QUARTER_PI);*/
  readoutCount = 0;
  background(0);
  fill(255);
  
  //readout("Raw Mag", rawMag);
  //readout("Raw Rot", rawRot);

  ///*
  // SUPER jank mouse input
  float mX = mouseX - (width / 2.0);
  float mY = -(mouseY - (height / 2.0));
  if (mousePressed) {
    PVector toMouse = new PVector(mX, mY);
    float angleBetweenPathAndMouse = lastNoTurnInput.heading() - toMouse.heading();
    float distBetweenPathAndMouse = toMouse.mag() * sin(angleBetweenPathAndMouse);
    iRot = constrain(map(distBetweenPathAndMouse, -200, 200, -QUARTER_PI, QUARTER_PI), -QUARTER_PI, QUARTER_PI);
    //iRot = constrain(map(mX, -200, 200, -QUARTER_PI, QUARTER_PI), -QUARTER_PI, QUARTER_PI);
  } else {
    iX = mX;
    iY = mY;
    iRot = 0;
    lastNoTurnInput = new PVector(mX, mY);
  }
  // really hacky way of emulating gamepad input with the mouse
  float rawMag = constrain(sqrt(sq(constrain(iX, -200, 200)) + sq(constrain(iY, -200, 200))) / 200, 0, 1);
  float rawRot = iRot / QUARTER_PI;
  //*/
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
