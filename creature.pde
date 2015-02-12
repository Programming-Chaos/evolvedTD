import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.AABB;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;

class creature {
  // All creatures have a Box2D body, a genome, and some other qualities:
  // fitness, health, a max health, angle they are facing, etc.
  Body body;

  Genome g;
  // communication traits
  boolean scent;          // used to determine if creature is capable of producing scent
  float scentStrength;    // how strong the creature's scent is
  int scentColor;         // store an integer for different colors

  float energy;   // used for reproduction and movement, given to offspring? gained from resources/food
  float fitness; // used for selection
  float health; // 0 health, creature dies
  float maxHealth = 100; // should be evolved
  float angle;
  boolean alive; // dead creatures remain in the swarm to have a breeding chance
  int round_counter; //Counter to track how many rounds/generations the individual creature has been alive

  // Constructor, creates a new creature at the given location and angle
  // This constructor is generally only used for the first wave, after that creatures are created from parents.
  creature(float x, float y, float a) {

    angle = a;                  // set the creature's angle
    g = new Genome();           // call the genome's constructor function to generate a new, random genome
    makeBody(new Vec2(x, y));   // call the function that makes a Box2D body
    body.setUserData(this);     // required by Box2D
    energy = 20000;             // Starting energy
    health = maxHealth;         // initial health
    fitness = 0;                // initial fitness
    alive = true;               // creatures begin life alive
    scent = setScent(this);     // does creature produce scent
    scentStrength = setScentStrength(this);        // how strong is the scent
    scentColor = setScentColor(this); // what color is the scent

  }
  
  // copy constructor - this constucts a creature from a parent
  // notice that the starting energy, e, is supplied by the parent
  creature(creature cs,float e) {
    g = new genome();
    g.copy(cs.g);     // copy the parent's genome into this creature's genome
    angle = random(0, 2 * PI); // start at a random angle
    // Currently creatures are 'born' around a circle a fixed distance from the tower.
    // Birth locations should probably be evolved as part of the reproductive strategy and/or behavior
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle), 0.45 * worldWidth * cos(angle));  
    makeBody(pos);
    energy = e;   // starting energy comes from parent
    health = maxHealth;  // Probably should be evolved.
    fitness = 0;
    body.setUserData(this);
    alive = true;
    scent = setScent(this);      // does creature produce scent
    scentStrength = setScentStrength(this); // how strong is the scent
    scentColor = setScentColor(this); // what color is the scent
 }

  boolean getScent()        { return scent; }
  float getScentStrength()  { return scentStrength; }
  int getScentColor()       { return scentColor; }
  
  int setScentColor( creature c ) {
    FloatList l;
    float s;
    int val;
    l = c.g.scent.list();
    s = l.get(5); // the 5th gene determines scent color for now
    // map function goes here
    if( s >= 0 ) {
      return 1;
    } else {
      return 2;
    }
  }

  // set scentStrength
  float setScentStrength( creature c ) {
    float s;
    s = c.g.scent.avg();
    // mapping function goes here
    return s;
  }
  
  // function setScent will calculate the creatures scent value
  boolean setScent( creature c ) {
    float s;
    s = c.g.scent.sum();
    print(s + "\n");
    // need to add a mapping function here
    if( s >= 0 ) {
      return true;
    } else {
      return false;
    }
  }
  
  void mutate() {
    g.mutate(); // mutate the genome
  }
   
  // returns a vector to the creature's postion 
  Vec2 get_pos() {
    return(box2d.getBodyPixelCoord(body));
  }
  
  // adds some energy to the creature - called when the creature picks up food/resource
  void add_energy(int x) {
    energy += x;
  }
  
  float getEnergy() {
    return energy;
  }
  
  float getMass() {
    return body.getMass();
  }
  
  float getForce() {
    return g.getForce();
  }
  
  float getDensity() {
    return g.getDensity();
  }
  
  // This function removes the body from the box2d world
  void killBody() {
      box2d.destroyBody(body);
  }
  
  boolean alive() {
    return alive;
  }
  
  double getCompat() {
    return g.getCompat();
  }
  
  // This function calculates the torques the creature produces to turn, as a 
  // function of what it senses in the environment
  double calcTorque() { 
    Vec2 pos2 = box2d.getBodyPixelCoord(body);  // get the creature's position
    int l = 50; // distance of the sensor from the body (should be evolved)
    int foodAheadL,foodAheadR,creatureAheadL,creatureAheadR,rockAheadL,rockAheadR;
    float scentAheadL,scentAheadR;
    double sensorX,sensorY;
    // left sensor check
    // Begin by calculating the x,y position of the left sensor
    // (Currently the angle of the sensors is fixed, angle PI*0.40, length 50 pixels, these should be evolved
    sensorX = pos2.x + l * cos(-1 * (body.getAngle() + PI * 0.40)); 
    sensorY = pos2.y + l * sin(-1 * (body.getAngle() + PI * 0.40));
    foodAheadL = environ.checkForFood(sensorX, sensorY);     // Check if there's food 'under' the left sensor
    creatureAheadL = environ.checkForCreature(sensorX, sensorY);  // Check if there's a creature 'under' the left sensor
    rockAheadL = environ.checkForRock(sensorX, sensorY); // Check if there's a rock 'under' the left sensor
    scentAheadL = environ.getScent(sensorX, sensorY);  // Get the amount of scent at the left sensor
    // right sensor check
    // Begin by calculating the x,y position of the right sensor
    sensorX = pos2.x + l * cos(-1 * (body.getAngle() + PI * 0.60)); 
    sensorY = pos2.y + l * sin(-1 * (body.getAngle() + PI * 0.60));
    // Then do all of the right sensor checks
    foodAheadR = environ.checkForFood(sensorX, sensorY); 
    creatureAheadR = environ.checkForCreature(sensorX, sensorY); 
    rockAheadR = environ.checkForRock(sensorX, sensorY);
    scentAheadR = environ.getScent(sensorX, sensorY);
    // Set the torque to zero, then add in the effect of the sensors
    double torque = 0;
    // If there's food ahead on the left, turn by the evolved amount of torque for food: Behavior(0)
    torque += foodAheadL * g.getBehavior(0); 
    // If there's food ahead on the right, turn by the evolved amount of torque for food: Behavior(0), but in the opposite, -1, direction
    torque += foodAheadR * -1 * g.getBehavior(0);
    // Similar turns for creatures and rocks
    torque += creatureAheadL * g.getBehavior(1);
    torque += creatureAheadR * -1 * g.getBehavior(1);
    torque += rockAheadL * g.getBehavior(2);
    torque += rockAheadR * -1 * g.getBehavior(2);
    // Take the square root of the amout of scent detected on the left (right), factor in the evolved response to smelling food, and add that to the torque
    // Take the squareroot of the scent to reduce over correction
    torque += sqrt(scentAheadL) * g.getBehavior(3);
    torque += sqrt(scentAheadR) * -1 * g.getBehavior(3);
    //println(torque); 
    return torque;
  }
  
  // Amount of forward force applied to the creature, this is evolved, hence gotten from the genome (g.getForce())
  float calcForce() {
    float f = g.getForce();
    return f;
  }
  
  // Calculates a creature's fitness, which determines its probability of reproducing
  void calcFitness() {
    fitness = 0;
    fitness += energy;  // More energy = more fitness
    fitness += health;  // More health = more fitness
    if (alive) {        // Staying alive = more fitness
      fitness *= 2;
    }
    // Note that unrealistically dead creatures can reproduce, which is necessary in cases where a player kills a whole wave
  }
  
  void change_health(int h) {
    health += h;
  }
  
  float getFitness() {
    return fitness;
  }
  
  // The update function is called every timestep
  // It updates the creature's postion, including applying turning torques,
  // and checks if the creature has died.
  void update() {
    Vec2 pos2 = box2d.getBodyPixelCoord(body);
    if (!alive) { // dead creatures don't update
      return;
    }
    float a = body.getAngle();
    float m = body.getMass();
    float f = calcForce();
    double torque = 0;
    torque = calcTorque();
    body.applyTorque((float)torque);
    // Angular velocity is reduced each timestep to mimic friction (and keep creatures from spinning endlessly)
    body.setAngularVelocity(body.getAngularVelocity() * 0.9);
    if (energy > 0) { // If there's energy left apply force
      body.applyForce(new Vec2(f * cos(a - 4.7), f * sin(a - 4.7)), body.getWorldCenter()); 
      energy = energy - abs(2 + (f * 0.005));
    }
    
    // Creatures that run off one side of the world wrap to the other side.
    if (pos2.x < -0.5 * worldWidth) {
      pos2.x += worldWidth;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.x > 0.5 * worldWidth) {
      pos2.x -= worldWidth;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.y < -0.5 * worldHeight) {
      pos2.y += worldHeight;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.y > 0.5 * worldHeight) {
      pos2.y -= worldHeight;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }

    if (health <=0) { // if out of health have the creature "die".  Stops participating in the world, still exists for reproducton
      alive = false;
      killBody(); // if its no longer alive the body can be killed - otherwise it still "in" the world.  Have to make sure the body isn't referenced elsewhere
    }
  }
  
  // Called every timestep (if the display is on) draws the creature
  void display() {
    if (!alive) { // dead creatures aren't displayed
      return;
    }
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();

    Fixture f = body.getFixtureList();  // This is a list of the Box2D fixtures (segments) of the creature
    PolygonShape ps; // Create a polygone variable
    // set some shape drawing modes
    rectMode(CENTER);
    ellipseMode(CENTER);
    pushMatrix();  // Stores the current drawing reference frame
    translate(pos.x, pos.y);  // Move the drawing reference frame to the creature's position
    rotate(-a);  // Rotate the drawing reference frame to point in the direction of the creature
    stroke(0);   // Draw polygons with edges
    while(f != null) {  // While there are still Box2D fixtures in the body, draw them
      fill(g.getcolor());  // Get the creature's color, creatures could evolve a different color for each segement
      ps = (PolygonShape)f.getShape();  // From the fixture list get the fixture's shape
      beginShape();   // Begin drawing the shape
      for (int i = 0; i < 3; i++) {
        Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));  // Get the vertex of the Box2D polygon/fixture, translate it to pixel coordinates (from Box2D coordinates)
        vertex(v.x, v.y);  // Draw that vertex
      }
      endShape(CLOSE);
      f = f.getNext();  // Get the next fixture from the fixture list
    }
    // Add some eyespots
    fill(0);
    Vec2 eye = g.getpoint(6);
    ellipse(eye.x, eye.y, 5, 5);
    ellipse(-1 * eye.x, eye.y, 5, 5);
    fill(255);
    ellipse(eye.x, eye.y - 1, 2, 2);
    ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    popMatrix();
    
    // Draw the "feelers", this is mostly for debugging
    float sensorX,sensorY;
    // Note that the length (50) and angles PI*40 and PI*60 are the same as when calculating the sensor postions in getTorque()
    int l = 50;
    sensorX = pos.x + l * cos(-1 * (body.getAngle() + PI * 0.40));
    sensorY = pos.y + l * sin(-1 * (body.getAngle() + PI * 0.40));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(pos.x, pos.y, sensorX, sensorY);
    //foodAhead = environ.checkForFood(sensorX,sensorY); // environ is a global
    sensorX = pos.x + l * cos(-1 * (body.getAngle() + PI * 0.60));
    sensorY = pos.y + l * sin(-1 * (body.getAngle() + PI * 0.60));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(pos.x, pos.y, sensorX, sensorY);
    
    pushMatrix(); // Draws a "health" bar above the creature
    translate(pos.x, pos.y);
    noFill();
    stroke(0);
    int offset = (int)max(g.getWidth(), g.getLength()); // get the largest dimension of the creature
    rect(0, -1 * offset, 0.1 * maxHealth, 3); // draw the health bar that much above it  
    noStroke();
    fill(0, 0, 255);
    rect(0, -1 * offset, 0.1 * health, 3);
    //Text to display the round counter of each creature for debug purposes
    //text((int)round_counter, 0.2*width,-0.25*height);
    popMatrix();
  }

  // This function makes a Box2D body for the creature and adds it to the box2d world
  void makeBody(Vec2 center) {
    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();  // Define a new Box2D body object
    bd.type = BodyType.DYNAMIC;  // Make the body dynamic (Box2d bodies can also be static: unmoving)
    bd.position.set(box2d.coordPixelsToWorld(center));  // set the postion of the body
    bd.linearDamping = 0.9;  // Give it some friction, could be evolved
    bd.setAngle(angle);      // Set the body angle to be the creature's angle
    body = box2d.createBody(bd);  // Create the body, not that it currently has no shape
    
    // Define a polygon object, this will be used to make the body fixtures
    PolygonShape sd;

    Vec2[] vertices3;  // Define an array of (3) vertices that will be used to define each fixture
    float density = g.getDensity();
    
    for (int i = 0; i < g.numsegments; i++) {  // For each segment
      sd = new PolygonShape();  // Create a new polygone

      vertices3  = new Vec2[3];  // Create an array of 3 new vectors
      // Next create a segment, pie slice, of the creature by defining 3 vertices of a poly gone
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0, 0));  // First vertex is at the center of the creature
      vertices3[1] = box2d.vectorPixelsToWorld(g.getpoint(i));   // Second and third vertices are evolved, so get from the genome
      vertices3[2] = box2d.vectorPixelsToWorld(g.getpoint(i + 1));
      //  sd is the polygon shape, create it from the array of 3 vertices
      sd.set(vertices3, vertices3.length);
      FixtureDef fd = new FixtureDef();  // Create a new Box2d fixture
      fd.shape = sd;  // Give the fixture a shape = polygon that was just created
      fd.density = density;  // give it a density
      fd.restitution = g.getRestitution();  // Give it a restitution (bounciness)
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body
    }
    
    // now repeat the whole process for the other side of the creature
    for (int i = 0; i < g.numsegments; i++) {
      sd = new PolygonShape();
      vertices3  = new Vec2[3];
      //vertices[i] = box2d.vectorPixelsToWorld(g.getpoint(i));
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0,0));
      vertices3[1] = box2d.vectorPixelsToWorld(g.getflippedpoint(i));      
      vertices3[2] = box2d.vectorPixelsToWorld(g.getflippedpoint(i + 1));
      sd.set(vertices3, vertices3.length);
      FixtureDef fd = new FixtureDef();
      fd.shape = sd;
      fd.density = density;
      fd.restitution = g.getRestitution();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
      body.createFixture(fd);
    }
  }
}
