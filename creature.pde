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
  genome g;
  float energy;   // used for reproduction and movement, given to offspring? gained from resources/food
  float fitness; // used for selection
  float health; // 0 health, creature dies
  float maxHealth = 100; // should be evolved
  float angle;
  boolean alive; // dead creatures remain in the swarm to have a breeding chance

  // Constructor, creates a new creature at the given location and angle
  // This constructor is generally only used for the first wave, after that creatures are created from parents.
  creature(float x, float y, float a) {
    angle = a;  // set the creature's angle
    g = new genome();  // call the genome's constructor function to generate a new, random genome
    makeBody(new Vec2(x, y));  // call the function that makes a Box2D body
    body.setUserData(this);    // required by Box2D
    energy = 20000;            // Starting energy 
    health = maxHealth;  // initial health
    fitness = 0;   // initial fitness
    alive = true;   // creatures begin life alive
  }
  
  // copy constructor - this constucts a creature from a parent
  // notice that the starting energy, e, is supplied by the parent
  creature(creature cs,float e) {
    g = new genome();
    g.copy(cs.g);     // copy the parent's genome into this creature's genome
    angle = random(0, 2 * PI); // start at a random angle
    // Currently creatures are 'born' around a circle a fixed distance from the tower.
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle), 0.45 * worldWidth * cos(angle));  
    makeBody(pos);
    energy = e;
    health = maxHealth;  // Probably should be evolved.
    fitness = 0;
    body.setUserData(this);
    alive = true; 
 }
  
  void mutate() {
    g.mutate(); // mutate the genome
  }
   
  Vec2 get_pos() {
    return(box2d.getBodyPixelCoord(body));
  }
  
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
  
  double calcTorque() { // creature senses the environment and generates a turning torque
    Vec2 pos2 = box2d.getBodyPixelCoord(body);
    int l = 50; // distance of the sensor from the body (should be evolved)
    int foodAheadL,foodAheadR,creatureAheadL,creatureAheadR,rockAheadL,rockAheadR;
    float scentAheadL,scentAheadR;
    double sensorX,sensorY;
    // left sensor check
    sensorX = pos2.x + l * cos(-1 * (body.getAngle() + PI * 0.40)); // calculate the x,y position of the left sensor
    sensorY = pos2.y + l * sin(-1 * (body.getAngle() + PI * 0.40));
    foodAheadL = environ.checkForFood(sensorX, sensorY); // environ is a global
    creatureAheadL = environ.checkForCreature(sensorX, sensorY);
    rockAheadL = environ.checkForRock(sensorX, sensorY);
    scentAheadL = environ.getScent(sensorX, sensorY);
    // right sensor check
    sensorX = pos2.x + l * cos(-1 * (body.getAngle() + PI * 0.60)); // calculate the x,y position of the right sensor
    sensorY = pos2.y + l * sin(-1 * (body.getAngle() + PI * 0.60));
    foodAheadR = environ.checkForFood(sensorX, sensorY); // environ is a global
    creatureAheadR = environ.checkForCreature(sensorX, sensorY); // environ is a global
    rockAheadR = environ.checkForRock(sensorX, sensorY);
    scentAheadR = environ.getScent(sensorX, sensorY);
    double torque = 0;
    torque += foodAheadL * g.getBehavior(0); // use the same genetic value for food, but negative for R sensor
    torque += foodAheadR * -1 * g.getBehavior(0);
    torque += creatureAheadL * g.getBehavior(1);
    torque += creatureAheadR * -1 * g.getBehavior(1);
    torque += rockAheadL * g.getBehavior(2);
    torque += rockAheadR * -1 * g.getBehavior(2);
    torque += sqrt(scentAheadL) * g.getBehavior(3); // take the squareroot of the scent to reduce over correction
    torque += sqrt(scentAheadR) * -1 * g.getBehavior(3);
    //println(torque); 
    return torque;
  }
  
  float calcForce() {
    float f = g.getForce();
    return f;
  }
  
  void calcFitness() {
    fitness = 0;
    fitness += energy;
    fitness += health;
    if (alive) {
      fitness *= 2;
    }
  }
  
  void change_health(int h) {
    health += h;
  }
  
  float getFitness() {
    return fitness;
  }
  
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

    body.setAngularVelocity(body.getAngularVelocity() * 0.9);
    if (energy > 0) { // if there's energy left apply force
      body.applyForce(new Vec2(f * cos(a - 4.7), f * sin(a - 4.7)), body.getWorldCenter()); 
      energy = energy - abs(2 + (f * 0.005));
    }
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
  
  // Drawing the shape
  void display() {
    if (!alive) { // dead creatures aren't displayed
      return;
    }
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();

    Fixture f = body.getFixtureList();
    PolygonShape ps; // = (PolygonShape) f.getShape(); 
    rectMode(CENTER);
    ellipseMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
    stroke(0);
    //noStroke();
    int shade = 126;
    while(f != null) {
      fill(g.getcolor());
      ps = (PolygonShape)f.getShape();
      beginShape();
      for (int i = 0; i < 3; i++) {
        Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));
        vertex(v.x, v.y);
      }
      endShape(CLOSE);
      f = f.getNext();
    }
    fill(0);
    Vec2 eye = g.getpoint(6);
    ellipse(eye.x, eye.y, 5, 5);
    ellipse(-1 * eye.x, eye.y, 5, 5);
    fill(255);
    ellipse(eye.x, eye.y - 1, 2, 2);
    ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    popMatrix();
    
    // "feelers"
    float sensorX,sensorY;
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
    
    pushMatrix(); // draws a "health" bar above the creature
    translate(pos.x, pos.y);
    noFill();
    stroke(0);
    int offset = (int)max(g.getWidth(), g.getLength()); // get the largest dimension of the creature
    rect(0, -1 * offset, 0.1 * maxHealth, 3); // draw the health bar that much above it  
    noStroke();
    fill(0, 0, 255);
    rect(0, -1 * offset, 0.1 * health, 3);
    popMatrix();
    
  }

  // This function adds a creature to the box2d world
  void makeBody(Vec2 center) {
    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    bd.linearDamping = 0.9;
    //bd.setAngle(random(0,7));
    bd.setAngle(angle);
    body = box2d.createBody(bd);
    
    // Define a polygon (this is what we use for a rectangle)
    PolygonShape sd;// = new PolygonShape();
    
    //Vec2[] vertices = new Vec2[g.numgenes];
    Vec2[] vertices3;
    float density = g.getDensity();
    
    for (int i = 0; i < g.numsegments; i++) {
      sd = new PolygonShape();

      vertices3  = new Vec2[3];
      //vertices[i] = box2d.vectorPixelsToWorld(g.getpoint(i));
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0, 0));
      vertices3[1] = box2d.vectorPixelsToWorld(g.getpoint(i));      
      vertices3[2] = box2d.vectorPixelsToWorld(g.getpoint(i + 1));
      sd.set(vertices3, vertices3.length);
      FixtureDef fd = new FixtureDef();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535; //#ffffff; // interacts with everything
      fd.shape = sd;
      fd.density = density;
      fd.restitution = g.getRestitution();
      body.createFixture(fd);
    }
    
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
      body.createFixture(fd);
    }
  }
}
