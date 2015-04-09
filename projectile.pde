class projectile {
  Body the_projectile;
  int radius;
  float angle;
  boolean remove = false;
  int damage; // how much damge the projectile does
  PImage bullet;    // declare image for gun
  PImage bulletalt1; // alternate images (if any)
  PImage bulletalt2;
  PImage bulletalt3;
  char type;
  int imagetimer = 0;
  int speed;
  /* type is the projectile type
   * r: rail gun bullet
   * l: plasmagun "bullet"
   * i: ice "bullet"
   */
  
  // constructor, creates a projectile
  projectile(float x, float y, float a, int d, char t, int s) {
    radius = 2;
    angle = a;
    damage = d;
    speed = s;
    makebody(x, y);
    the_projectile.setUserData(this);
    type = t;
    
    switch (type){
      case 'r':
        bullet = loadImage("assets/Turret-Railgun/Bullet48x48a-01.png");
        break;
      case 'p':
        bullet = loadImage("assets/photon72/Photon01a.png");
        bulletalt1 = loadImage("assets/photon72/Photon02a.png");
        bulletalt2 = loadImage("assets/photon72/Photon03a.png");
        bulletalt3 = loadImage("assets/photon72/Photon04a.png");
        break;
      case 'i':
        bullet = loadImage("assets/Turret-Freeze/freezeblast.png");
        break;
    }
  }
  
  void update(){
    if (box2d.getBodyPixelCoord(the_projectile).x < (-1*(worldWidth/2)) || box2d.getBodyPixelCoord(the_projectile).x > (worldWidth/2))remove = true;
    if (box2d.getBodyPixelCoord(the_projectile).y < (-1*(worldHeight/2)) || box2d.getBodyPixelCoord(the_projectile).y > (worldHeight/2))remove = true;
    Vec2 velocity;
    velocity = the_projectile.getLinearVelocity();
    if(velocity.length()< 30){  // remove slow projectiles
      remove = true;
    }
  }   
  
  // This function removes the particle from the box2d world
  void killBody() {
    if (the_projectile != null) {
      box2d.destroyBody(the_projectile);
    }
  }
  
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(the_projectile));
  }
  
  int get_damage() {  // returns the amount of damage a projectile does
    return damage;
  }

  void display() {
    if (imagetimer == 12)
      imagetimer = 0;
    Vec2 pos = box2d.getBodyPixelCoord(the_projectile);
    pushMatrix();
    translate(pos.x, pos.y);
    switch (type){
      case 'r':
        rotate(the_projectile.getAngle() + PI);
        image(bullet, -24, -24);
        break;
      case 'p':
        rotate(the_projectile.getAngle() + PI/2);
        if (imagetimer >= 0 && imagetimer < 3)
          image(bullet, -36, -36);
        if (imagetimer >= 3 && imagetimer < 6)
          image(bulletalt1, -36, -36);
        if (imagetimer >= 6 && imagetimer < 9)
          image(bulletalt2, -36, -36);
        if (imagetimer >= 9 && imagetimer < 12)
          image(bulletalt3, -36, -36);
        break;
      case 'i':
        rotate(the_projectile.getAngle() + PI/2);
        image(bullet, -24, -24);
        break;
    }
    /*
    fill(0, 0, 0);
    stroke(0);
    ellipse(0,0, radius*2, radius*2);
    */
    popMatrix();
    imagetimer++;
  }
  
  void makebody(float x, float y) {
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
    the_projectile.setLinearVelocity(new Vec2(speed*cos(angle), -1*speed*sin(angle)));
  }
}
