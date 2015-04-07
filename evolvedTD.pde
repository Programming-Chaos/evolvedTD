import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.AABB;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;


int cameraX, cameraY, cameraZ; // location of the camera
static int worldWidth = 2500;  // world size
static int worldHeight = 2500;
static int zoomOffset = 2163;  // (translate(cameraX, cameraY, cameraZ - zoomOffset)
float worldRatioX, worldRatioY;

// see
State state = State.RUNNING;
State stateSaved = state;

int timesteps = 0;
int timepergeneration = 1500;
int generation = 0;

boolean playSound = true;      // play game sounds
boolean playSoundSave = true;  // restore sound setting on unhide
boolean display = true;        // should the world be displayed - false speeds thing up considerably
boolean displayFood = true;    // not displaying food speeds things up somewhat
boolean displayScent = false;  // not displaying scent speeds things up a lot
boolean buttonpressed = false;
boolean autofire = true;

population the_pop;            // the population of creatures
tower the_tower;               // a tower object
player the_player;             // the player!
ArrayList<food> foods;         // list of food objects in the world
ArrayList<rock> rocks;         // list of rock objects in the world
ArrayList<Panel> panels;

Box2DProcessing box2d;         // the box2d world object
environment environ;           // the environment object

Minim minim;
AudioPlayer gunshot, gunshotalt;
AudioPlayer thunder;

int lasttime;                  // used to track the time between iterations to measure the true framerate

float mouse_x;
float mouse_y;

// Tables for data collection
Table c_traits;
Table c_avgs;
Table reproduction;
Table sensing;
Table metabolism;
Table lifetime;
Table p_impact;
Table p_stats;
Table env;

// Variables for data collection
int fStart;
int fTotal = 0;
int fConsumed = 0;

void setup() {
  //size(850,850,P3D);  // default window size
  size(800,800,P3D);             // window size, and makes it a 3D window
  worldRatioX = (float)worldWidth/width;
  worldRatioY = (float)worldHeight/height;
  box2d = new Box2DProcessing(this);
  box2d.createWorld();           // create the box2d world, which tracks physical objects
  PFont font = createFont("Arial", 100);
  textFont(font);
  panels = new ArrayList<Panel>();
  the_player = new player();
  the_player.towers.add(new tower(0, 0, 'r'));

  minim = new Minim(this);
  gunshot = minim.loadFile("assets/railgunfire01long.mp3");
  gunshotalt = minim.loadFile("assets/railgunfire01slow_01.mp3");
  thunder = minim.loadFile("assets/Thunder.mp3");

  box2d.setGravity(0, 0);        // no gravity - it would pull creatures towards one edge of the screen
  box2d.listenForCollisions();   // set the world to listen for collisions, calls beginContact and endContact() functions defined below
  frameRate(200);                // sets the framerate, in many cases the actual framerate will be lower due to the number of objects moving nad interacting
  cameraX = 0;
  cameraY = 0;
  cameraZ = 2150;
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

  // Run unit tests
  Genome testGenome = new Genome();
  testGenome.testChromosome();
  testGenome.testMutation();

  // Init data tables
  initTables();
}

void draw() {
  // println("fps: " + 1000.0 / (millis() - lasttime)); // used to print the framerate for debugging
  lasttime = millis();
  mouse_x = ((((mouseX-(width/2))*worldRatioX)/((float)zoomOffset/cameraZ))+cameraX);
  mouse_y = ((((mouseY-(height/2))*worldRatioY)/((float)zoomOffset/cameraZ))+cameraY);

  if (state == State.RUNNING) { // if running, increment the number of timesteps, at some max the wave/generation ends
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
  
  for (int i = 0; i < rocks.size(); i++) { // go through the list of rocks and if any was pushed outside map, remove it.
    rock r = rocks.get(i);
    Vec2 rockPos = r.getPos();
    if (r != null) {
      if (rockPos.x > 1250 || rockPos.x < -1250 || 
          rockPos.y > 1250 || rockPos.y < -1250) {
        r.killBody();
        rocks.remove(r); // if a rock was hit out of map on x dimension, remove it from the list
        i--;
      }
    }
  }
  
  if (display) {
    for (rock r: rocks) { // go through the array list of rocks and display them
      r.display();
    }
  }

  the_player.update();
  if (display) {
    the_player.display(); // display the interface for the player
  }

  /*
    the_tower.update();
    if (display) {
    the_tower.display(); // display the tower
    }
  */

  if (state == State.RUNNING) {
    the_pop.update(); // update the population, i.e. move the creatures
  }

  if (the_pop.get_alive() == 0) { // if after updating the population is empty, go ahead and start the next generation
    nextgeneration(); // call the function to set the next generation
    timesteps = 0;
  }

  if (display) {
    the_pop.display(); // redisplay the creatures
  }

  // If state is running then step through time!
  if (state == State.RUNNING) {
    box2d.step();
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
      autofire = !autofire;
      break;
    case 'z':
      // center camera and zoom all the way out
      cameraX = 0;
      cameraY = 0;
      cameraZ = zoomOffset;
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
      if (state == State.STAGED)
        state = State.RUNNING;
      else if (state != State.PAUSED)
        state = State.PAUSED;
      else
        state = State.RUNNING;
      break;
    case 'u':  // toggle upgrade window
      the_player.upgradePanel.enabled = !the_player.upgradePanel.enabled;
      if (state == State.STAGED) state = State.RUNNING;
      break;
    case 'm':
      playSound = !playSound;
      break;
    case 'v':
      display = !display;
      // mute on hide
      if (!display) {
        playSoundSave = playSound;
        playSound = false;
      } else {
        playSound = playSoundSave;
      }
      break;
    case 'q':
      displayFood = !displayFood;
      break;
    case 'n':
      displayScent = !displayScent;
      break;
    case '?':
      the_player.helpPanel.enabled = !the_player.helpPanel.enabled;
      break;
    case '1':
    case '2':
      the_player.towers.get(0).activeweapon = (key-'0');
      break;
    case '3':
    case '4':
      the_player.towers.get(0).switchtargetMode(key);
      break;
    default:

    }
    if (cameraZ < 100) { // much closer than this and the screen goes blank
      cameraZ = 100;
    }
  }
}

void beginContact(Contact cp) { // called when two box2d objects collide
  if (state != State.RUNNING) { // probably not necessary?
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
    p1.senses.Set_Taste(p2);
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
    p1.senses.Set_Taste(p2);
    if (p2 != null) {
      p2.setRemove(true); // flag the food to be removed during the food's update (you can't(?) kill the food's body in the middle of this function)
    }
  }

  // check the class of the objects and respond accordingly
  if (o1.getClass() == creature.class && o2.getClass() == projectile.class) {
    // projectiles damage creatures
    creature p1 = (creature)o1;
    projectile p2 = (projectile)o2;
    if (f1.getUserData().getClass() == creature.Segment.class) {
      p1.changeHealth(round(-1*(p2.get_damage()/((creature.Segment)f1.getUserData()).armor)));
    }
    if (f1.getUserData().getClass() == creature.Appendage.class) {
      p1.changeHealth(round(-1*(p2.get_damage()/((creature.Appendage)f1.getUserData()).armor)));
    }
    p2.setRemove(true);
  }

  if (o1.getClass() == projectile.class && o2.getClass() == creature.class) {// check the class of the objects and respond accordingly
    // projectiles damage creatures
    creature p1 = (creature)o2;
    projectile p2 = (projectile)o1;
    if (f2.getUserData().getClass() == creature.Segment.class) {
      p1.changeHealth(round(-1*(p2.get_damage()/((creature.Segment)f2.getUserData()).armor)));
    }
    if (f2.getUserData().getClass() == creature.Appendage.class) {
      p1.changeHealth(round(-1*(p2.get_damage()/((creature.Appendage)f2.getUserData()).armor)));
    }
    p2.setRemove(true);
  }
  if (o1.getClass() == creature.class && o2.getClass() == creature.class) {// check the class of the objects and respond accordingly
    creature p1 = (creature)o1;
    creature p2 = (creature)o2;
    Vec2 pos_1 = box2d.getBodyPixelCoord(b1);
    Vec2 pos_2 = box2d.getBodyPixelCoord(b2);
    int collision_1 = int(nf(p1.num, 0) + nf(p2.num, 0));
    int collision_2 = int(nf(p2.num, 0) + nf(p1.num, 0));
    int ID;

    if (collision_1 > collision_2) {
      ID = collision_1;
    } else {
      ID = collision_2;
    }

    p1.senses.Add_Side_Pressure(ID, PI);
    p2.senses.Add_Side_Pressure(ID, atan((pos_1.y - pos_2.y)/(pos_1.x-pos_2.x)));
  }
}


void endContact(Contact cp) {
  if (state != State.RUNNING) { // probably not necessary?
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

  if (o1.getClass() == creature.class && o2.getClass() == creature.class) {// check the class of the objects and respond accordingly
    creature p1 = (creature)o1;
    creature p2 = (creature)o2;
    Vec2 pos_1 = box2d.getBodyPixelCoord(b1);
    Vec2 pos_2 = box2d.getBodyPixelCoord(b2);
    int collision_1 = int(nf(p1.num, 0) + nf(p2.num, 0));
    int collision_2 = int(nf(p2.num, 0) + nf(p1.num, 0));
    int ID;
    if (collision_1 > collision_2) {
      ID = collision_1;
    } else {
      ID = collision_2;
    }
    p1.senses.Remove_Side_Pressure(ID);
    p2.senses.Remove_Side_Pressure(ID);
  }




  if (o1.getClass() == creature.class && o2.getClass() == food.class) {// check the class of the objects and respond accordingly
    // creatures grab food
    creature p1 = (creature)o1;
    p1.senses.Remove_Taste();
  }

  // check the class of the objects and respond accordingly
  if (o1.getClass() == food.class && o2.getClass() == creature.class) {
    // creatures grab food
    creature p1 = (creature)o2;
    p1.senses.Remove_Taste();
  }


}

void place_food() { // done once at the beginning of the game
  foods = new ArrayList<food>();
  for (int i = 0; i < 50; i++) {
    food f = new food((int)random(-0.2 * worldWidth, 0.2 * worldWidth),
                      (int)random(-0.2 * worldHeight, 0.2 * worldHeight)); // places food randomly near the tower
    foods.add(f);
  }
  
  // data collection
  fStart = foods.size();
  fTotal += 50;
}

void nextgeneration() {
  generation++;
  the_pop.next_generation(); // update the population
  add_food(); // add some more food
  the_player.next_generation(); // have the tower update itself, reset energy etc.
  // if in autofire mode don't both pausing - useful for evolving in
  // the background
  if (!autofire) {
    stateSaved = state;
    state = State.STAGED; // pause the game
    the_player.upgradePanel.enabled = true;
  }
}

void add_food() { // done after each wave/generation
  for (int i = 0; i < 35; i++) { // why add exactly 35 food each time?
    food f = new food((int)random(-0.4*worldWidth,0.3*worldWidth), (int)random(-0.3*worldHeight,0.4*worldHeight)); // places food randomly near the tower
    foods.add(f);
  }
  
  // data collection  
  fStart = foods.size();
  fTotal += 10;
}

void mousePressed() { // called if either mouse button is pressed
  // fire the weapons
  if (mouseButton == LEFT) {
    the_player.mouse_pressed();
    if (!buttonpressed) {
      if (state == State.RUNNING)
        for (tower t : the_player.towers)
          t.fire(); // have the tower fire its active weapon if unpaused
    }
    buttonpressed = false;
  }

  // select a creature
  if (mouseButton == RIGHT) {
    int radius = 20;
    // find a creature
    the_player.selectedCreature = null;
    for (creature c : the_pop.swarm) {
      Vec2 location = c.getPos();
      if (mouse_x < location.x + radius && mouse_x > location.x - radius
          && mouse_y < location.y + radius && mouse_y > location.y - radius) {
        the_player.selectedCreature = c;
        // zoom in on click
        cameraZ = 400;
        break;
      }
    }
  }

  // for dubugging purposes draw a cricle where the program thinks the mouse is in the world - it's right(?)
  pushMatrix();
  hint(DISABLE_DEPTH_TEST);
  translate(cameraX,cameraY,cameraZ-zoomOffset);
  fill(255,0,255,255);
  ellipse((((float)mouseX-(width/2))*worldRatioX),(((float)mouseY-(height/2))*worldRatioX),50,50);
  hint(ENABLE_DEPTH_TEST);
  popMatrix();
}

void initTables() {
  //creature traits
  c_traits = new Table();
  c_traits.addColumn("   Gen   ");
  c_traits.addColumn("   Creature ID   ");
  c_traits.addColumn("   Mass   ");
  c_traits.addColumn("   Width   ");
  c_traits.addColumn("   Density   ");
  c_traits.addColumn("   Armor   ");
  c_traits.addColumn("   Wing #   ");
  c_traits.addColumn("   Wing Size   ");
  c_traits.addColumn("   Antennae #   ");
  c_traits.addColumn("   Color   ");
  c_traits.addColumn("   Velocity   ");
  c_traits.addColumn("   Acceleration   ");
  c_traits.addColumn("   Max HP   ");
  
  //creature averages
  c_avgs = new Table();
  c_avgs.addColumn("   Gen   ");
  c_avgs.addColumn("   Avg Mass   ");
  c_avgs.addColumn("   Avg Width   ");
  c_avgs.addColumn("   Avg Density   ");
  c_avgs.addColumn("   Avg Armor   ");
  c_avgs.addColumn("   Avg Wing #   ");
  c_avgs.addColumn("   Avg Wing Size   ");
  c_avgs.addColumn("   Avg Antennae #   ");
  c_avgs.addColumn("   Avg Color   ");
  c_avgs.addColumn("   Avg Velocity   ");
  c_avgs.addColumn("   Avg Acceleration   ");
  c_avgs.addColumn("   Avg Max HP   ");
  
  //reproduction traits
  reproduction = new Table();
  reproduction.addColumn("   Gen   ");
  reproduction.addColumn("   Creature ID   ");
  reproduction.addColumn("   Spawn X   ");
  reproduction.addColumn("   Spawn Y   ");
  reproduction.addColumn("   # of Gametes   ");
  reproduction.addColumn("   Gamete Cost   ");
  reproduction.addColumn("   Gamete Time   ");
  
  //sensing traits
  sensing = new Table();
  sensing.addColumn("   Gen   ");
  sensing.addColumn("   Creature ID   ");
  sensing.addColumn("   Creature Scent   ");
  sensing.addColumn("   Creature Taste   ");
  
  //metabolism traits
  metabolism = new Table();
  metabolism.addColumn("   Gen   ");
  metabolism.addColumn("   Creature ID   ");
  metabolism.addColumn("   Total Energy Space   ");
  metabolism.addColumn("   Total Energy Consumed   ");
  metabolism.addColumn("   Locomotion Space   ");
  metabolism.addColumn("   Locomotion Used   ");
  metabolism.addColumn("   Reproduction Space   ");
  metabolism.addColumn("   Reproduction Used   ");
  metabolism.addColumn("   Reproduction Passed   ");
  metabolism.addColumn("   Health Space   ");
  metabolism.addColumn("   Health Used   ");
  metabolism.addColumn("   Total Energy Used   ");
  
  //lifetime ticks
  lifetime = new Table();
  lifetime.addColumn("   Gen   ");
  lifetime.addColumn("   Creature ID   ");
  lifetime.addColumn("   Ticks on Algae   ");
  lifetime.addColumn("   Ticks on Water   ");
  lifetime.addColumn("   Ticks on Rock   ");
  lifetime.addColumn("   Total Lifetime   ");
  
  //player impact
  p_impact = new Table();
  p_impact.addColumn("   Gen   ");
  p_impact.addColumn("   Creature ID   ");
  p_impact.addColumn("   Died/Survived   ");
  p_impact.addColumn("   Times Hit by Tower   ");
  p_impact.addColumn("   HP Removed by Tower   ");
  p_impact.addColumn("   Final HP   ");
  
  //player stats
  p_stats = new Table();
  p_stats.addColumn("   Gen   ");
  p_stats.addColumn("   Tower ID   ");
  p_stats.addColumn("   Round # of Shots   ");
  p_stats.addColumn("   Total # of Shots   ");
  p_stats.addColumn("   Round Successful Hits   ");
  p_stats.addColumn("   Total Successful Hits   ");
  p_stats.addColumn("   Round Rock Hits   ");
  p_stats.addColumn("   Total Rock Hits   ");
  p_stats.addColumn("   Round Accuracy   ");
  p_stats.addColumn("   Overall Accuracy   ");
  p_stats.addColumn("   Round Avg RoF   ");
  p_stats.addColumn("   Overall Avg RoF   ");
  p_stats.addColumn("   Round # of Kills   ");
  p_stats.addColumn("   Total # of Kills   ");
  p_stats.addColumn("   Round Avg Shots per Kill   ");
  p_stats.addColumn("   Overall Avg Shots per Kill   ");
  
  //environment stats
  env = new Table();
  env.addColumn("   Gen   ");
  env.addColumn("   Food at Start   ");
  env.addColumn("   Food at End   ");
  env.addColumn("   Food Consumed   ");
  env.addColumn("   Total Food   ");
  env.addColumn("   Total Consumed   ");
  env.addColumn("   Round Lightning Strikes   ");
  env.addColumn("   Round Lightning Kills   ");
  env.addColumn("   Round Lightning Accuracy   ");
  env.addColumn("   Total Lightning Strikes   ");
  env.addColumn("   Total Lightning Kills   ");
  env.addColumn("   Overall Lightning Accuracy   ");
}

//Test for writing data to excel file
void writeTables() {
  saveTable(c_traits, "data/c_traits.csv");
  saveTable(c_avgs, "data/c_avgs.csv");
  saveTable(reproduction, "data/reproduction.csv");
  saveTable(sensing, "data/sensing.csv");
  saveTable(metabolism, "data/metabolism.csv");
  saveTable(lifetime, "data/lifetime.csv");
  saveTable(p_impact, "data/p_impact.csv");
  saveTable(p_stats, "data/p_stats.csv");
  saveTable(env, "data/env.csv");
}
