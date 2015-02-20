import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;


int cameraX, cameraY, cameraZ; // location of the camera
int worldWidth = 2500;         // size in pixels of the world
int worldHeight = 2500;

int state = 1;                 // 1 - running; 2 - paused between generations; 3 - controls
int oldstate = 1;              // used to store the previous state to return to after displaying controls
int timesteps = 0;
int timepergeneration = 1500;
int generation = 0;

boolean paused = false;        // is it paused
boolean display = true;        // should the world be displayed - false speeds thing up considerably
boolean displayFood = true;    // not displaying food speeds things up somewhat
boolean displayScent = true;   // not displaying scent speeds things up a lot

population the_pop;            // the population of creatures
tower the_tower;               // a tower object
ArrayList<food> foods;         // list of food objects in the world
ArrayList<rock> rocks;         // list of rock objects in the world

Box2DProcessing box2d;         // the box2d world object
environment environ;           // the environment object

Minim minim;
AudioPlayer gunshot;

int lasttime;                  // used to track the time between iterations to measure the true framerate

void setup() {
  size(850,850,P3D);             // window size, and makes it a 3D window
  box2d = new Box2DProcessing(this);
  box2d.createWorld();           // create the box2d world, which tracks physical objects
  the_tower = new tower();
  
  minim = new Minim(this);
  gunshot = minim.loadFile("Cannon.mp3");

  box2d.setGravity(0, 0);        // no gravity - it would pull creatures towards one edge of the screen
  box2d.listenForCollisions();   // set the world to listen for collisions, calls beginContact and endContact() functions defined below
  frameRate(200);                // sets the framerate, in many cases the actual framerate will be lower due to the number of objects moving nad interacting
  cameraX = 0;
  cameraY = 0;
  cameraZ = 300;
  the_pop = new population();

  place_food();                  // calls the place food function below
  rocks = new ArrayList<rock>();
  for (int i = 0; i < 10; i++) { // creates 10 random rocks,
    rock r = new rock((int)random(-0.5 * worldWidth, 0.5 * worldWidth),
                      (int)random(-0.5 * worldHeight, 0.5 * worldHeight));
    rocks.add(r);
  }
  rectMode(CENTER);              // drawing mode fore rectangles,

  environ = new environment();   // must occur after creatures, etc. created
  lasttime = 0;
}

void draw() {
  // println("fps: " + 1000.0 / (millis() - lasttime)); // used to print the framerate for debugging
  lasttime = millis();
  

  if (!paused && state == 1) { // if running, increment the number of timesteps, at some max the wave/generation ends
    timesteps++;
  }
  if (timesteps > timepergeneration) { // end of a wave/generation
    nextgeneration(); // call the function to set the next generation
    timesteps = 0;
  }
  camera(cameraX, cameraY, cameraZ, cameraX, cameraY, 0, 0, 1, 0); // place the camera and point it in the right direction, happens repeatedly because the user can move the camera
  background(100); // fill in the background
  if (display) {
    environ.display();
  }

  for (int i = 0; i < foods.size(); i++) { // go through the list of food and if any was collided into by a creature, remove it.
    food f = foods.get(i);
    if (f != null) {
      if (f.update() == 1) {
        foods.remove(i); // if a food was eaten remove it from the list
      }
    }
  }

  if (display && displayFood) {
    for (food f: foods) { // go through the array list of food and display them
      f.display();
    }
  }
  if (display) {
    for (rock r: rocks) { // go through the array list of rocks and display them
      r.display();
    }
  }

  the_tower.update();
  if (display) {
    the_tower.display(); // display the tower
  }

  if (!paused) {
    the_pop.update(); // update the population, i.e. move the creatures
  }

  if (the_pop.get_alive() == 0) { // if after updating the population is empty, go ahead and start the next generation
    nextgeneration(); // call the function to set the next generation
    timesteps = 0;
  }

  if (display) {
    the_pop.display(); // redisplay the creatures
  }

  // If not paused and state is running then step through time!
  if (!paused && state == 1) {
    box2d.step();
  }
  if (state == 3) {
    display_controls();
  }
}  // end of draw loop

void keyPressed() { // if a key is pressed this function is called
  int scale = 100;
  if (key == CODED) { // if its a coded key, e.g. and arrow key
    switch(keyCode) {
    case UP:
      cameraY-= (4 + int(cameraZ/scale));
      break;
    case DOWN:
      cameraY+= (4 + int(cameraZ/scale));
      break;
    case LEFT:
      cameraX-= (4 + int(cameraZ/scale));
      break;
    case RIGHT:
      cameraX+= (4 + int(cameraZ/scale));
      break;
    }
  }
  else {
    switch(key) { // else its a regular character
    case 'a':
      the_tower.toggleautofire();
      break;
    case 'z':
      cameraZ = 2150; // zoom all the way out
      break;
    case 'w':
      cameraZ -= (12 + int(cameraZ / scale)); // zoom in a little
      break;
    case 's':
      cameraZ += (12 + int(cameraZ / scale)); // zoom out a little
      break;
    case 'c':   // center the camera
      cameraX = 0;
      cameraY = 0;
      break;
    case 'p':  // toggle paused state
      paused = !paused;
      break;
    case 'v':
      display = !display;
      break;
    case 'q':
      displayFood = !displayFood;
      break;
    case 'n':
      displayScent = !displayScent;
      break;
    case '?':
      controls(); // call the instructions function
      break;
    case '1':
    case '2':
      the_tower.switchweapon(key);
      break;
    default:

    }
    if (cameraZ < 100) { // much closer than this and the screen goes blank
      cameraZ = 100;
    }
  }
}

void beginContact(Contact cp) { // called when two box2d objects collide
  if (paused) { // probably not necessary
    return;
  }
  // Get both fixtures that collided from the Contact object cp (which was passed in as an argument)
  Fixture f1 = cp.getFixtureA();
  Fixture f2 = cp.getFixtureB();
  // Get the bodies that the fixtures are attached to
  Body b1 = f1.getBody();
  Body b2 = f2.getBody();
  // Get the objects that reference these bodies, i.e. the userData
  Object o1 = b1.getUserData();
  Object o2 = b2.getUserData();

  if (o1.getClass() == creature.class && o2.getClass() == food.class) {// check the class of the objects and respond accordingly
    // creatures grab food
    creature p1 = (creature)o1;
    p1.addEnergy(20000); // getting food is valuable
    food p2 = (food)o2;
    if (p2 != null) {
      p2.setRemove(true); // flag the food to be removed during the food's update (you can't(?) kill the food's body in the middle of this function)
    }
  }

  // check the class of the objects and respond accordingly
  if (o1.getClass() == food.class && o2.getClass() == creature.class) {
    // creatures grab food
    creature p1 = (creature)o2;
    p1.addEnergy(20000); // getting food is valuable
    food p2 = (food)o1;
    if (p2 != null) {
      p2.setRemove(true); // flag the food to be removed during the food's update (you can't(?) kill the food's body in the middle of this function)
    }
  }

  // check the class of the objects and respond accordingly
  if (o1.getClass() == creature.class && o2.getClass() == projectile.class) {
    // projectiles damage creatures
    Fixture f = b1.getFixtureList();
    int c = 0;
    while (f != f1) {
      f = f.getNext();
      c++;
    }
    c %= 8;
    creature p1 = (creature)o1;
    projectile p2 = (projectile)o2;
    p1.changeHealth((int)(-1*(p2.get_damage()/p1.getArmor(c))));
  }

  if (o1.getClass() == projectile.class && o2.getClass() == creature.class) {// check the class of the objects and respond accordingly
    // projectiles damage creatures
    Fixture f = b1.getFixtureList();
    int c = 0;
    while (f != f1) {
      f = f.getNext();
      c++;
    }
    c %= 8;
    creature p1 = (creature)o2;
    projectile p2 = (projectile)o1;
    p1.changeHealth((int)(-1*(p2.get_damage()/p1.getArmor(c))));
  }

  // nothing happens if two creatures collide
  // Nothing happens if rocks collide with creatures, food with rocks, etc.
}

void endContact(Contact cp) { // a required function, but doesn't do anything
  ;
}

void place_food() { // done once at the beginning of the game
  foods = new ArrayList<food>();
  for (int i = 0; i < 50; i++) {
    food f = new food((int)random(-0.4 * worldWidth, 0.4 * worldWidth),
                      (int)random(-0.4 * worldHeight, 0.4 * worldHeight)); // places food randomly near the tower
    foods.add(f);
  }
}

void nextgeneration() {
  generation++;
  println(generation);
  the_pop.next_generation(); // update the population
  add_food(); // add some more food
  the_tower.next_generation(); // have the tower update itself, reset energy etc.
  if (!the_tower.autofire) { // if in autofire mode don't both pausing - useful for evolving in the background
    paused = true; // pause the game
  }
}

void add_food() { // done after each wave/generation
  for (int i = 0; i < 10; i++) { // why add exactly 10 food each time?
    food f = new food((int)random(-0.4*worldWidth,0.4*worldWidth), (int)random(-0.4*worldHeight,0.4*worldHeight)); // places food randomly near the tower
    foods.add(f);
  }
}

void mousePressed() { // called if the (left) mouse button is pressed
  float x,y;
  // first we have to try to figure out, given the pixel coordinates of the mouse and the camera position, where in the virtual world the cursor is
  // this calculation is not correct
  x = cameraX + (cameraZ * sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
  y = cameraY + (cameraZ * sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15

  if (!paused)
    the_tower.fire(); // have the tower fire its active weapon if unpaused

  // for dubugging purposes draw a cricle where the program thinks the mouse is in the world - it's right(?)
  pushMatrix();
  translate(x,y);
  ellipse(0,0,30,30);
  popMatrix();
}

void controls() {
  if (state != 3) {
    paused = true;
    oldstate = state; // so the program can go back to it
    state = 3;
  }
  else {
    paused = false;
    state = oldstate;
  }
}

void display_controls() {
  fill(200,200,200,200); // grey slightly transparent rectangle
  int leftalign = -90;
  int topalign = -80;
  pushMatrix();
  translate(cameraX, cameraY, cameraZ - 200);
  rect(0,0,200,200);
  fill(0);
  textSize(10);
  text("Controls",leftalign,topalign);
  textSize(7);
  text("w/s - zoom in/out", leftalign, topalign + 10);
  text("Arrow keys - move camera", leftalign, topalign + 18);
  text("z - zoom out", leftalign, topalign + 26);
  text("p - pause/unpause", leftalign, topalign + 34);
  text("Mouse button - fire", leftalign, topalign + 42);
  text("Number keys - switch weapons", leftalign, topalign + 50);
  text("q - hide/unhide food", leftalign, topalign + 58);
  text("n - hide/unhide scent", leftalign, topalign + 66);
  text("v - hide/unhide screen", leftalign, topalign + 74);
  text("? - show/hide controls", leftalign, topalign + 82);
  text("a - toggle autofire", leftalign, topalign + 90);
  popMatrix();
}
