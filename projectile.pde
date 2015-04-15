class projectile {
  Body the_projectile;
  int radius;
  float angle;
  float xpos, ypos;
  boolean remove = false;
  int damage; // how much damge the projectile does
  PImage bullet;    // declare image for gun
  PImage bulletalt1; // alternate images (if any)
  PImage bulletalt2;
  PImage bulletalt3;
  char type;
  int speed;
  int imagetimer = 0;
  int traveltimer = 0;
  int wobblespeed = 8;
  int wobbletimer = (-1*wobblespeed);
  float wobblestrength = 0; // this is how far in/out the edges of the orb will wobble, 40 is the maximum
  /* type is the projectile type
   * r: rail gun bullet
   * p: plasmagun "bullet"
   * i: ice "bullet"
   */
  
  // constructor, creates a projectile
  projectile(float x, float y, float a, int d, char t, int s) {
    the_projectile = null;
    xpos = x;
    ypos = y;
    type = t;
    angle = a;
    damage = d;
    speed = s;
    if (type == 'g') {
      radius = 40;
      wobblestrength = 35;
      makebodyElectron(xpos, ypos);
    }
    else {
      radius = 2;
      makebody(xpos, ypos);
      
      switch (type){
        case 'r':
          bullet = loadImage("assets/Turret-Railgun/Bullet48x48a-01.png");
          break;
        case 'p':
          bullet = loadImage("assets/Turret-Plasma/photon72/Photon01a.png");
          bulletalt1 = loadImage("assets/Turret-Plasma/photon72/Photon02a.png");
          bulletalt2 = loadImage("assets/Turret-Plasma/photon72/Photon03a.png");
          bulletalt3 = loadImage("assets/Turret-Plasma/photon72/Photon04a.png");
          break;
        case 'i':
          bullet = loadImage("assets/Turret-Freeze/freezeblast.png");
          break;
        case 'l':
          bullet = loadImage("assets/Turret-Laser/Lazer Blast-01.png");
          break;
      }
    }
    the_projectile.setUserData(this);
  }
  
  void update(){
    if (box2d.getBodyPixelCoord(the_projectile).x < (-1*(worldWidth/2)) || box2d.getBodyPixelCoord(the_projectile).x > (worldWidth/2))remove = true;
    if (box2d.getBodyPixelCoord(the_projectile).y < (-1*(worldHeight/2)) || box2d.getBodyPixelCoord(the_projectile).y > (worldHeight/2))remove = true;
    if (type == 'g') { // electron clouds don't get removed for being slow but they do have some electrifying interactions with creatures
      if (traveltimer > speed) {
        remove = true;
        for (creature c : the_pop.swarm) c.shocked = false;
      }
      else {
        if (box2d.getBodyPixelCoord(the_projectile).x-radius <= (-1*(worldWidth/2)) || box2d.getBodyPixelCoord(the_projectile).x+radius >= (worldWidth/2)) {
          the_projectile.setLinearVelocity(new Vec2(-1*the_projectile.getLinearVelocity().x,the_projectile.getLinearVelocity().y));
          angle *= -1;
          wobblestrength += 15;
        }
        if (box2d.getBodyPixelCoord(the_projectile).y-radius <= (-1*(worldHeight/2)) || box2d.getBodyPixelCoord(the_projectile).y+radius >= (worldHeight/2)) {
          the_projectile.setLinearVelocity(new Vec2(the_projectile.getLinearVelocity().x,-1*the_projectile.getLinearVelocity().y));
          angle *= -1;
          wobblestrength += 15;
        }
        Vec2 cpos;
        Vec2 pos = box2d.getBodyPixelCoord(the_projectile);
        float distance;
        for (creature c : the_pop.swarm) {
          cpos = box2d.getBodyPixelCoord(c.body);
          distance = sqrt(((cpos.x-pos.x)*(cpos.x-pos.x))+((cpos.y-pos.y)*(cpos.y-pos.y)))-40;
          float maxRange = (damage*50);
          if (distance < maxRange && c.alive) {
            beginShape();
            noFill();
            stroke(255,255,100,255);
            strokeWeight(1);
            vertex(pos.x,pos.y);
            int loopfor = round(random(2,8));
            for (int i = 1; i < loopfor; i++)
              vertex(pos.x+((float)(cpos.x-pos.x)*i/loopfor)+random(-0.5*distance/loopfor,0.5*damage/loopfor),pos.y+((float)(cpos.y-pos.y)*i/loopfor)+random(-0.5*damage/loopfor,0.5*damage/loopfor));
            vertex(pos.x+((float)(cpos.x-pos.x)/3),pos.y+((float)(cpos.y-pos.y)/3));
            vertex(cpos.x,cpos.y);
            endShape();
            
            c.health += (-1*damage*((maxRange-distance)/maxRange));
            c.senses.Set_Current_Pain((damage*((maxRange-distance)/maxRange)));
            // increase or decrease this number to lengthen or shorten the
            // animation time on hit
            c.hit_indicator = 5;
            // data collection
            if (!c.shocked) {
              c.hits_by_tower++;
              c.shocked = true;
            }
            c.hp_removed_by_tower += ((-1*damage*((maxRange-distance)/maxRange)));
          }
        }
      }
      return;
    }
    Vec2 velocity;
    velocity = the_projectile.getLinearVelocity();
    if(velocity.length() < 30){  // remove slow projectiles
      remove = true;
    }
  }   
  
  // This function removes the particle from the box2d world
  void killBody() {
    if (the_projectile != null) {
      the_projectile.setUserData(null);
      for (Fixture f = the_projectile.getFixtureList(); f != null; f = f.getNext())
        f.setUserData(null);
      box2d.destroyBody(the_projectile);
    }
  }
  
  Vec2 getPos() {
    return box2d.getBodyPixelCoord(the_projectile);
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
      case 'l':
        rotate(the_projectile.getAngle() + PI/2);
        image(bullet, -128, -256);
        break;
      case 'g':
        if (wobbletimer == wobblespeed) wobbletimer = (-1*wobblespeed);
        if (wobblestrength > 0) wobblestrength *= 0.96; // 4% of wobble is lost each timestep
        if (wobblestrength < 1) wobblestrength = 0;
        if (traveltimer > round((float)speed*((float)2/3)) && traveltimer <= speed) { // increasingly random stuff as the orb becomes more unstable and disintegrates
          pushMatrix();
            rotate(the_projectile.getAngle());
            fill(100,255,200,200-(100*((traveltimer - round((float)speed*((float)2/3)))/(speed - round((float)speed*((float)2/3))))));//(198-(traveltimer-201)));
            stroke(1,200-(100*((traveltimer - round((float)speed*((float)2/3)))/(speed - round((float)speed*((float)2/3)))))); // round((float)speed*2/3) < traveltimer < speed
            strokeWeight(0.1);
            beginShape();
            float rand;
            for (int c = 0; c < 50; c++) {
              rand = ((((float)radius*0.8)*(((float)traveltimer - ((float)speed*((float)2/3)))/(speed - ((float)speed*((float)2/3)))))*random(-1,1));
              vertex(((radius+rand)*cos(c*PI/25))-rand,((radius+rand)*sin(c*PI/25)));
            }
            endShape(CLOSE);
            stroke(1);
            strokeWeight(1);
          popMatrix();
        }
        else { // stable trajectory, if a little wobbly
          rotate(the_projectile.getAngle());
          strokeWeight(0.1);
          fill(100,255,200,200);
          float wobble = ((abs(((float)wobbletimer*2)/wobblespeed)-1)*wobblestrength);
          ellipse(0,0,(radius+wobble)*2,(radius-wobble)*2);
          strokeWeight(1);
        }
        traveltimer++;
        wobbletimer++;
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
  
  void makebodyElectron(float x, float y) {
    BodyDef bd = new BodyDef();
    bd.angle = angle;
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    bd.type = BodyType.KINEMATIC;
    bd.linearDamping = 0.1;
    
    the_projectile = box2d.createBody(bd);
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.filter.categoryBits = 1; // electron clouds are in filter category 1
    fd.filter.maskBits = 65535;  // interacts with everything
    fd.shape = sd;
    fd.density = 40; // should be upgradable
    the_projectile.createFixture(fd);
    the_projectile.setLinearVelocity(new Vec2(20*cos(angle), -1*20*sin(angle))); // 20 is the speed of electron clouds
  }
}
