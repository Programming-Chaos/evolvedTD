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

  Genome genome;         // encodes the creature's genetic information

  // communication traits
  boolean scent;         // used to determine if creature is capable of producing scent
  float scentStrength;   // how strong the creature's scent is
  int scentColor;        // store an integer for different colors

  float energy;          // used for reproduction and movement, given to offspring? gained from resources/food
  float fitness;         // used for selection
  float health;          // 0 health, creature dies
  float maxHealth = 100; // should be evolved
  float angle;
  boolean alive;         // dead creatures remain in the swarm to have a breeding chance
  int round_counter;     //Counter to track how many rounds/generations the individual creature has been alive
  int numSegments;
  FloatList armor;
  float density;

  // Constructor, creates a new creature at the given location and angle
  // This constructor is generally only used for the first wave, after that creatures are created from parents.
  creature(float x, float y, float a) {
    angle = a;
    genome = new Genome();

    numSegments = getNumSegments();
    computeArmor();
    float averageArmor = armor.sum() / numSegments;
    density = (getDensity() * averageArmor);

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
  creature(creature cs, float e) {
    angle = random(0, 2 * PI); // start at a random angle
    genome = new Genome(cs.genome);

    numSegments = getNumSegments();
    computeArmor();
    float averageArmor = armor.sum() / numSegments;
    density = (getDensity() * averageArmor);

    // Currently creatures are 'born' around a circle a fixed distance
    // from the tower. Birth locations should probably be evolved as
    // part of the reproductive strategy and/or behavior
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle),
                        0.45 * worldWidth * cos(angle));
    makeBody(pos);
    energy = e;         // starting energy comes from parent
    health = maxHealth; // probably should be evolved
    fitness = 0;
    body.setUserData(this);
    alive = true;

    scent = setScent(this);                 // does creature produce scent
    scentStrength = setScentStrength(this); // how strong is the scent
    scentColor = setScentColor(this);       // what color is the scent
 }

  boolean getScent()        { return scent; }
  float getScentStrength()  { return scentStrength; }
  int getScentColor()       { return scentColor; }
  
  int setScentColor( creature c ) {
    FloatList l;
    float s;
    int val;
    l = c.genome.scent.list();
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
    s = c.genome.scent.avg();
    // mapping function goes here
    return s;
  }
  
  // function setScent will calculate the creatures scent value
  boolean setScent( creature c ) {
    float s;
    s = c.genome.scent.sum();
    // need to add a mapping function here
    if( s >= 0 ) {
      return true;
    } else {
      return false;
    }
  }

  // TODO: factor out with meiosis
  void mutate() {
    genome.mutate(); // mutate the genome
  }
   
  // returns a vector to the creature's postion 
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(body));
  }
  
  // adds some energy to the creature - called when the creature picks
  // up food/resource
  void addEnergy(int x) {
    energy += x;
  }

  float getEnergy() {
    return energy;
  }
  
  // Mapping from allele value to color is a sigmoid mapping to 0 to
  // 255 centered on 126
  private color getColor() {
    // TODO: refactor for color per segment
    float redColor = genome.redColor.sum();
    float greenColor = genome.greenColor.sum();
    float blueColor = genome.blueColor.sum();

    int r = 126 + (int)(126*(redColor/(1+abs(redColor))));
    int g = 126 + (int)(126*(greenColor/(1+abs(greenColor))));
    int b = 126 + (int)(126*(blueColor/(1+abs(blueColor))));

    return color(r, g, b);
  }

  // Gets the end point of the ith segment/rib/spine used to create
  // the creatures body
  private Vec2 getPoint(int i) {
    Vec2 a = new Vec2();
    float segment = genome.segments[i].endPoint.sum();
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));;
    }
    a.x = (float)(l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Gets the end point of the ith segment/rib/spine on the other side
  // of the creatures body
  private Vec2 getFlippedPoint(int i) {
    // TODO: reduce code duplication
    Vec2 a = new Vec2();
    float segment = genome.segments[i].endPoint.sum();
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));
    }
    a.x = (float)(-1 * l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Calculate and return the width of the creature
  private float getWidth() {
    // TODO: Move this to creature
    float maxX = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.x > maxX) {
        maxX = temp.x;
      }
    }
    return 2*maxX;
  }

  // Calculate and return the length of the creature
  private float getLength() {
    float maxY = 0;
    float minY = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.y > maxY) {
        maxY = temp.y;
      }
      if (temp.y < minY) {
        minY = temp.y;
      }
    }
    return (maxY - minY);
  }

  float getMass() {
    return body.getMass();
  }

  // Forward force to accelerate the creature, evolved, but
  // (currently) doesn't change anytime durning a wave
  private float getForce() {
    // -infinity to infinity linear
    return (500 + 10 * genome.forwardForce.sum());
  }

  // How bouncy a creature is, one of the basic box2D body parameters,
  // no idea how it evolves or if it has any value to the creatures
  private float getRestitution() {
    // TODO: refactor for restitution per segment
    float r = genome.restitution.sum();
    return 0.5 + (0.5 * (r / (1 + abs(r))));
  }

  // can be from 2 to Genome.MAX_SEGMENTS
  int getNumSegments() {
    int ret = round(genome.expressedSegments.avg() + 8);
    if (ret < 2)
      return 2;
    if (ret > Genome.MAX_SEGMENTS)
      return Genome.MAX_SEGMENTS;
    return ret;
  }

  // Density of a creature for the box2D "physical" body.

  // Box2D automatically handles the mass as density times area, so
  // that when a force is applied to a body the correct acceleration
  // is generated.
  private float getDensity() {
    // TODO: refactor for density per segment

    // if the value is negative, density approaches zero asympototically from 10
    if (genome.density.sum() < 0)
      return 10 * (1 / (1 + abs(genome.density.sum())));
    // otherwise, the value is positive and density grows as 10 plus the square
    // root of the evolved value
    return 10 + sqrt(genome.density.sum()); // limit 0 to infinity
  }

  private void computeArmor() {
    armor = new FloatList(numSegments);
    for (int i = 0; i < numSegments; i++) {
      // compute armor value for each segment [0.1, infinity]
      float a = genome.segments[i].armor.avg();
      if (1 + a < 0.1)
        a = 0.1;
      else
        a = 1 + a;
      armor.append(a);
    }
  }

  // This function removes the body from the box2d world
  void killBody() {
      box2d.destroyBody(body);
  }
  
  boolean alive() {
    return alive;
  }
  
  double getCompat() {
    //return genome.getCompat();
    return 0;
  }

  // This is the base turning force, it is modified by getBehavior()
  // above, depending on what type of object was sensed to start
  // turning
  private int getTurningForce() {
    // -infinity to infinity linear
    return (int)(100 + 10 * genome.turningForce.sum());
  }

  // Returns the amount of turning force (just a decimal number) the
  // creature has evolved to apply when it senses either food, another
  // creature, a rock, or a (food) scent.
  private double getBehavior(Genome.Trait trait) {
    return getTurningForce() * trait.sum(); // there's a turning force
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
    // If there's food ahead on the left, turn by the evolved torque
    torque += foodAheadL * getBehavior(genome.food);
    // If there's food ahead on the right, turn by the evolved torque
    // but in the opposite direction
    torque += foodAheadR * -1 * getBehavior(genome.food);
    // Similar turns for creatures and rocks
    torque += creatureAheadL * getBehavior(genome.creature);
    torque += creatureAheadR * -1 * getBehavior(genome.creature);
    torque += rockAheadL * getBehavior(genome.rock);
    torque += rockAheadR * -1 * getBehavior(genome.rock);
    // Take the square root of the amout of scent detected on the left
    // (right), factor in the evolved response to smelling food, and
    // add that to the torque Take the squareroot of the scent to
    // reduce over correction
    torque += sqrt(scentAheadL) * getBehavior(genome.scent);
    torque += sqrt(scentAheadR) * -1 * getBehavior(genome.scent);
    //println(torque);
    return torque;
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
  
  void changeHealth(int h) {
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
    float f = getForce();
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
    for(int c = 0; f != null; c++) {  // While there are still Box2D fixtures in the creature's body, draw them and get the next one
      c %= numSegments;
      fill(getColor()); // Get the creature's color
      strokeWeight(armor.get(c));
      ps = (PolygonShape)f.getShape();  // From the fixture list get the fixture's shape
      beginShape();   // Begin drawing the shape
      for (int i = 0; i < 3; i++) {
        Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));  // Get the vertex of the Box2D polygon/fixture, translate it to pixel coordinates (from Box2D coordinates)
        vertex(v.x, v.y);  // Draw that vertex
      }
      endShape(CLOSE);
      f = f.getNext();  // Get the next fixture from the fixture list
    }
    strokeWeight(1);
    // Add some eyespots
    fill(0);
    Vec2 eye = getPoint(6);
    ellipse(eye.x, eye.y, 5, 5);
    ellipse(-1 * eye.x, eye.y, 5, 5);
    fill(255);
    ellipse(eye.x, eye.y - 1, 2, 2);
    ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    popMatrix();
    
    // Draw the "feelers", this is mostly for debugging
    float sensorX,sensorY;
    // Note that the length (50) and angles PI*40 and PI*60 are the
    // same as when calculating the sensor postions in getTorque()
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
    // get the largest dimension of the creature
    int offset = (int)max(getWidth(), getLength());
    rect(0, -1 * offset, 0.1 * maxHealth, 3); // draw the health bar that much above it  
    noStroke();
    fill(0, 0, 255);
    rect(0, -1 * offset, 0.1 * health, 3);
    //Text to display the round counter of each creature for debug purposes
    //text((int)round_counter, 0.2*width,-0.25*height);
    popMatrix();
  }
  
  class segIndex {  // This class is a helper. One of these is attached to every segment of every creature
    int segmentIndex;  // This class's only variable is an index corresponding to of the creature's segments this is, so its armor can be referenced later
  }

  // This function makes a Box2D body for the creature and adds it to the box2d world
  void makeBody(Vec2 center) {
    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();  // Define a new Box2D body object
    bd.type = BodyType.DYNAMIC;  // Make the body dynamic (Box2d bodies can also be static: unmoving)
    bd.position.set(box2d.coordPixelsToWorld(center));  // set the postion of the body
    bd.linearDamping = 0.9;  // Give it some friction, could be evolved
    bd.setAngle(angle);      // Set the body angle to be the creature's angle
    body = box2d.createBody(bd);  // Create the body, note that it currently has no shape
    
    // Define a polygon object, this will be used to make the body fixtures
    PolygonShape sd;

    Vec2[] vertices3;  // Define an array of (3) vertices that will be used to define each fixture

    // For each segment
    for (int i = 0; i < numSegments; i++) {
      sd = new PolygonShape();  // Create a new polygon

      vertices3  = new Vec2[3];  // Create an array of 3 new vectors

      // Next create a segment, pie slice, of the creature by defining
      // 3 vertices of a poly gone

      // First vertex is at the center of the creature
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0, 0));
      // Second and third vertices are evolved, so get from the genome
      vertices3[1] = box2d.vectorPixelsToWorld(getPoint(i));
      vertices3[2] = box2d.vectorPixelsToWorld(getPoint(i + 1));

      // sd is the polygon shape, create it from the array of 3 vertices
      sd.set(vertices3, vertices3.length);
      // Create a new Box2d fixture
      FixtureDef fd = new FixtureDef();
      // Give the fixture a shape = polygon that was just created
      fd.shape = sd;
      fd.density = density;
      fd.restitution = getRestitution();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
//      fd.userData = new segIndex();
//      fd.userData.segmentIndex = i;
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body
    }
    
    // now repeat the whole process for the other side of the creature
    for (int i = 0; i < numSegments; i++) {
      sd = new PolygonShape();
      vertices3  = new Vec2[3];
      //vertices[i] = box2d.vectorPixelsToWorld(getpoint(i));
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0,0));
      vertices3[1] = box2d.vectorPixelsToWorld(getFlippedPoint(i));
      vertices3[2] = box2d.vectorPixelsToWorld(getFlippedPoint(i + 1));
      sd.set(vertices3, vertices3.length);
      FixtureDef fd = new FixtureDef();
      fd.shape = sd;
      fd.density = density;
      fd.restitution = getRestitution();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535; // interacts with everything
//      fd.userData = new segIndex();
//      fd.userData.segmentIndex = i;
      body.createFixture(fd);
    }
  }
}
