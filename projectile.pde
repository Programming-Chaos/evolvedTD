class projectile {
  Body the_projectile;
  int radius;
  float angle;
  boolean remove = false;
  int damage; // how much damge the projectile does
  PImage bullet;    // declare image for gun
  
  // constructor, creates a projectile
  projectile(int x, int y, float a, int d) {
    radius = (int)(2);
    angle = a;
    damage = d;
    makebody(x, y);
    the_projectile.setUserData(this);
    bullet = loadImage("Gunturret04a.png");
  }
  
  void update(){
    Vec2 velocity;
    velocity = the_projectile.getLinearVelocity();
    if(velocity.length()< 50){  // remove slow projectiles
      remove = true;
    }
  }   
  
  // This function removes the particle from the box2d world
  void killBody() {
    if (the_projectile != null) {
      box2d.destroyBody(the_projectile);
    }
  }
  
  Vec2 get_pos() {
    return(box2d.getBodyPixelCoord(the_projectile));
  }
  
  int get_damage() {  // returns the amount of damage a projectile does
    return damage;
  }
  
  void setRemove(boolean x) { // sets the projectile to be removed later
    remove = x;
  }
  
  Boolean getRemove(){
    return remove;
  }

  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(the_projectile);
    pushMatrix();
    translate(pos.x, pos.y);
    float c = the_projectile.getAngle();
    rotate(c + HALF_PI);
    image(bullet, -128, -128);
    /*
    fill(0, 0, 0);
    stroke(0);
    ellipse(0,0, radius*2, radius*2);
*/    
    popMatrix();
  }
  
  void makebody(int x, int y) {
    BodyDef bd = new BodyDef();
    bd.angle = angle;
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    bd.type = BodyType.DYNAMIC;
    bd.bullet = true;
    bd.linearDamping = 0.1;
    
    the_projectile = box2d.createBody(bd);
    // Define the shape -- a  (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.filter.categoryBits = 3; // projectiles are in category 3
    fd.filter.maskBits = 65533; // doesn't interact with food 
    fd.shape = sd;
    fd.density = 40; // should be upgradable
    the_projectile.createFixture(fd);
    the_projectile.setLinearVelocity(new Vec2(100*cos(angle), -100*sin(angle)));
  }
}
