class tower {
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int energyGain;       // energy gain per timestep
  int maxEnergy = 1000; // max energy the tower can have
  ArrayList<projectile> projectiles;  // list of active projectiles
  float angle;    // angle of tower's main, auto-fir weapon
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  PImage gun;    // declare image for gun
  PImage gunalt; // declare alternate image for animation
  PImage gunbase; // gun base
  boolean showgun = true; // show base gun image
  boolean showgunalt = false; // show alternate gun image
  int imagetimer; // timer for alternating gun images
  int soundtimer;
  float radius = 50;
  int targetMode = 1;
  int xpos; // x position of center of turret
  int ypos; // y position of center of turret
  int dmg; // damage value, changed by turret type
  int baseDamageRailgun = 20;
  int baseDamageFlamethrower = 200;
  int firerate; // autofire rate, lower values fire faster
  int baseFirerateRailgun = 25;
  int baseFirerateFlamethrower = 75;
  int projectileSpeed;
  int baseProjectileSpeed = 100;
  int ecost; // per fire energy cost
  boolean inTransit = true;
  boolean conflict = false;
  char type;
  /* type is the turret type
   * r: default rail gun
   * f: flamethrower
   */
  Body tower_body;

  // constructor function, initializes the tower
  tower(char t) {
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    projectiles = new ArrayList<projectile>();
    angle = 0;
    imagetimer = 0;
    soundtimer = 0;
    projectileSpeed = baseProjectileSpeed*(the_player.bulletSpeedUpgrades+1);

    xpos = round(mouse_x);
    ypos = round(mouse_y);
    type = t;

    switch (type){
      case 'r':
        the_player.numrailguns++;
        gunbase = loadImage("assets/Tower_base_02.png");
        gun = loadImage("assets/RailGun-01.png");
        gunalt = loadImage("assets/RailGun-a-01.png");
        dmg = baseDamageRailgun*(the_player.bulletDamageUpgrades+1);
        firerate = round((float)baseFirerateRailgun/(the_player.fireRateUpgrades+1));
        ecost = 10;
        break;
      case 'f':
        the_player.numflamethrowers++;
        gun = loadImage("assets/FlameThrower01-01.png");
        gunalt = loadImage("assets/FlameThrower02-01.png");
        gunbase = loadImage("assets/Turbase03256.png");
        dmg = baseDamageFlamethrower*(the_player.bulletDamageUpgrades+1);
        firerate = round((float)baseFirerateFlamethrower/(the_player.fireRateUpgrades+1));
        ecost = 50;
        break;
    }

    BodyDef bd = new BodyDef();
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(0, 17*(radius/80))));
    bd.type = BodyType.STATIC;
    bd.linearDamping = 0.9;

    tower_body = box2d.createBody(bd);
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.filter.categoryBits = 2; // food is in filter category 2
    fd.filter.maskBits = 65531; // doesn't interact with projectiles
    fd.shape = sd;
    fd.density = 100;
    tower_body.createFixture(fd);

    tower_body.setUserData(this);
  }

  void update() {
    update_projectiles();
    if (inTransit) {
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (tower t : the_player.towers) {
        if (t != the_player.pickedup)
          if (sqrt((t.xpos-xpos)*(t.xpos-xpos)+(t.ypos-ypos)*(t.ypos-ypos)) <= radius*2)
            conflict = true;
      }
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING){
      energy += energyGain;  // gain energy
      if (autofire) {
        Vec2 target;
        autofirecounter++;
        // only autofire every nth time step where n is the fire rate
        if (autofirecounter == firerate) {
          // target a random creature
          target = the_pop.vec_to_random_creature();
          // target the closest creature
          if (targetMode == 2) {
            target = the_pop.closest(new Vec2(0,0));
          }
          if (targetMode == 3) {
            target = the_pop.highestAlpha();
          }
          angle = atan2(target.y-ypos,target.x-xpos);
          fire_projectile();
          autofirecounter = 0;  // reset the counter
        }
      }
      else { // user controlled: calculate the angle to the mouse pointer and point at the mouse
        // calculate the location of the mouse pointer in the world
        //float x, y;
        //x = ((mouse_x/((float)zoomOffset/cameraZ))+cameraX-xpos);
        //y = ((mouse_y/((float)zoomOffset/cameraZ))+cameraY-ypos);
        //x = (cameraX+((mouseX-(width/2))*(cameraZ/(0.5*sqrt(width*width+height*height)))));
        //y = (cameraY+((mouseY-(height/2))*(cameraZ/(0.5*sqrt(width*width+height*height)))));
        //calculate the angle to the mouse pointer
        angle = atan2(mouse_y-ypos,mouse_x-xpos);//(ypos*((float)worldWidth/width)), x-(xpos*((float)worldWidth/width)));
      }
    }
  }

  void update_projectiles(){
    for (int i = projectiles.size() - 1; i >= 0; i--) {  // walk through particles to avoid missing one
      projectile p = projectiles.get(i);
      p.update();
      if(p.getRemove()){
        p.killBody();  // remove the box2d body
        projectiles.remove(i);  // remove the projectile from the list
      }
    }
  }

  void display() {
    /*
    // draw a line
    stroke(255, 0, 0);
    line(0, 0, 30*cos(angle), 30*sin(angle));
    //draw the tower
    ellipse(0, 0, 10, 10); // just a circle for now
    */
    image(gunbase,xpos-(radius*((float)128/80)),ypos-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    showgunalt = false;
    showgun = true;
    imagetimer++;
    if (imagetimer > 15) {
      showgunalt = false;
      showgun = true;
    }
    else {
      showgunalt = true;
      showgun = false;
    }

    pushMatrix();
    translate(xpos, ypos, 0);
    rotate(angle+(PI/2));
    if(showgun)image(gun,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    if(showgunalt)image(gunalt,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    popMatrix();

    for (projectile p: projectiles) { // display the active projectiles
      p.display();
    }

    // draw tower energy bar
    noFill();
    stroke(0);
    rect(xpos, ypos-30, 0.1*maxEnergy, 12);
    noStroke();
    fill(0, 0, 255);
    rect(xpos, ypos-30, 0.1*energy, 12);

    if (inTransit) {
    // draw the outline of the tower's box2D body
      pushMatrix();
      translate(box2d.getBodyPixelCoord(tower_body).x+xpos, box2d.getBodyPixelCoord(tower_body).y+ypos);
      fill(0, 0, 0, 0);
      if (conflict)stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
    }
    else if (the_player.placing) {
      for (tower t : the_player.towers) {
        if (t != the_player.pickedup) {
          pushMatrix();
          translate(box2d.getBodyPixelCoord(t.tower_body).x+xpos, box2d.getBodyPixelCoord(t.tower_body).y+ypos);
          fill(0, 0, 0, 0);
          stroke(0);
          ellipse(0, 0, radius*2, radius*2);
          stroke(0);
          popMatrix();
        }
      }
    }

    // display resources, now in player
    /*
    pushMatrix();
    hint(DISABLE_DEPTH_TEST);
      translate(cameraX, cameraY,cameraZ-400);  // centered and below the camera
      fill(0,0,0,200);
      textSize(8);
      text("Resources: "+(int)resources,0.2*width,-0.25*height);
    hint(ENABLE_DEPTH_TEST);
    popMatrix();
    */
  }

  void next_generation() { // update the tower
    energy = maxEnergy; // reset energy (could/should depend on remaining resources)
    for (projectile p: projectiles) {
      if (p != null) {
        //  p.killBody(); // not sure if this is necessary with the .clear() below
      }
    }
    projectiles.clear();
  }

  void switchtargetMode(char k) {
    if (k == '3'){
      targetMode = 2;
    }
    if (k == '4'){
      targetMode = 3;
    }
  }

  /* Firing, dropping rocks, etc. uses up some of the tower's energy */

  void fire_projectile() {
    if (energy < 10) {
      return;
    }
    projectile p = new projectile(xpos, ypos, angle, dmg, type, projectileSpeed);
    projectiles.add(p);
    energy -= ecost;
    imagetimer = 0;
    switch (type) {
      case 'r':
        soundtimer++;
        if (soundtimer == 3){
          soundtimer = 0;
          if (playSound) PlaySounds( "assets/railgunfire01long.mp3" );
        }
        else if (playSound) PlaySounds( "assets/railgunfire01slow_01.mp3" );
        break;
      case 'f':
        if (playSound) PlaySounds( "assets/ricochet1.mp3");
        break;
    }
  }

  void wave_fire() {
    if (energy < 5) return;
    if (inTransit) return;
    for (float a = 0; a < 2*PI ; a += ((2*PI)/20)) // postions of new projectiles are not at 0,0 to avoid collisions.
      projectiles.add(new projectile(xpos+(5*cos(a)), ypos+(5*sin(a)), a, dmg, type, projectileSpeed));
    energy -= 5;
    imagetimer = 0;
    if (playSound) {
      //      PlaySounds( gunshot );
        PlaySounds( "assets/railgunfire01long.mp3" );
      //      gunshot.rewind();
      //      gunshot.play();
    }
  }
}
