class BurntCreature {
  int timer;
  Vec2 center;
  float angle;
  ArrayList<Vec2> coords;
  boolean remove;
  
  BurntCreature(creature ctr) {
    remove = false;
    center = box2d.getBodyPixelCoord(ctr.body);
    angle = ctr.body.getAngle();
    timer = 40;
    coords = new ArrayList<Vec2>();
    for (int i = ctr.segments.size()-1; i >= 0; i--)
      coords.add(ctr.segments.get(i).frontPoint);
    for (int i = 0; i < ctr.segments.size(); i++)
      coords.add(new Vec2((-1*ctr.segments.get(i).backPoint.x),ctr.segments.get(i).backPoint.y));
  }
  
  void display() {
    pushMatrix();
    translate(center.x,center.y);
    rotate(-1*angle);
    noStroke();
    if (timer > 36)
      fill(255,(255-((timer-35)*63)),(255-((timer-35)*63)),255);
    else if (timer <= 36 && timer > 34)
      fill(255,255,255,255);
    else if (timer <= 34 && timer > 30)
      fill (((timer-31)*85),((timer-31)*85),((timer-31)*85),255);
    else if (timer <= 30 && timer > 20)
      fill (0,0,0,255);
    else if (timer <= 20)
      fill (0,0,0,(timer*12));
    beginShape();
    for (Vec2 v : coords)
      vertex(v.x,v.y);
    /*vertex(20, 20);
    vertex(40, 20);
    vertex(40, 40);
    vertex(60, 40);
    vertex(60, 60);
    vertex(20, 60);*/
    endShape(CLOSE);
    stroke(0);
    popMatrix();
    timer--;
  }
}

class tower {
  int ID;
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int energyGain;       // energy gain per timestep
  int maxEnergy = 1000; // max energy the tower can have
  ArrayList<projectile> projectiles;  // list of active projectiles
  ArrayList<BurntCreature> burntcreatures;
  float angle;    // angle of tower's main, auto-fir weapon
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  Animation firing;
  Animation targeting;
  PImage gunbase; // gun base
  int soundtimer;
  float radius = 50;
  int xpos; // x position of center of turret
  int ypos; // y position of center of turret
  int dmg; // damage value, changed by turret type
  int baseDamage;
  int firerate; // autofire rate, lower values fire faster
  int baseFirerate;
  int projectileSpeed;
  int baseProjectileSpeed;
  int ecost; // per fire energy cost
  int bulletSpeedUpgrades = 0;
  int bulletDamageUpgrades = 0;
  int fireRateUpgrades = 0;
  int bulletSpeedButtons[] = new int[5];
  int bulletDamageButtons[] = new int[5];
  int fireRateButtons[] = new int[5];
  int laserfiretimer = 0;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  boolean poweringup = false;
  Vec2 target;
  PImage laser1 = loadImage("assets/Turret-Laser/Lazer Blast-01.png");
  PImage laser2 = loadImage("assets/Turret-Laser/Lazer Blasta-01.png");
  char type;
  Panel upgradePanel;
  /* type is the turret type
   * r: default rail gun
   * l: plasmagun
   * i: freeze gun
   */
  Body tower_body;

  // constructor function, initializes the tower
  tower(char t, int id) {
    ID = id;
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    projectiles = new ArrayList<projectile>();
    burntcreatures = new ArrayList<BurntCreature>();
    firing = new Animation();
    targeting = new Animation();
    angle = 0;
    soundtimer = 0;
    target = new Vec2(0,0);

    xpos = round(mouse_x);
    ypos = round(mouse_y);
    type = t;

    switch (type){
      case 'r':
        baseDamage = 20;
        baseFirerate = 25;
        baseProjectileSpeed = 100;
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        gunbase = loadImage("assets/Turret-Railgun/Turbase03256.png");
        firing.addFrame(loadImage("assets/Turret-Railgun/RG001.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG005.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG004.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG003.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG002.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 10;
        break;
      case 'p':
        baseDamage = 100;
        baseFirerate = 75;
        baseProjectileSpeed = 150;
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        gunbase = loadImage("assets/Turret-Plasma/Turbase03256.png");
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap01-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap07-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap06-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap05-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap04-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap03-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap02-01.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 50;
        break;
      case 'i':
        baseDamage = 200; // functions as freeze duration since ice pellets don't do damage
        baseFirerate = 100;
        baseProjectileSpeed = 50;
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        gunbase = loadImage("assets/Turret-Freeze/turret2-01.png");
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze01.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze02.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze03.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze04.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 30;
        break;
      case 'l':
        baseDamage = 200;
        baseFirerate = 150;
        baseProjectileSpeed = 60; // functions as powerup ticks since speed is instantaneous
        projectileSpeed = round((float)baseProjectileSpeed/(bulletSpeedUpgrades+1));
        gunbase = loadImage("assets/Turret-Laser/Turret base 03-01.png");
        firing.addFrame(loadImage("assets/Turret-Laser/LaserGun01-01.png"));
        firing.addFrame(loadImage("assets/Turret-Laser/LaserGun02-01.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR00.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR01.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR02.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR03.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR04.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR05.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR06.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR07.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR08.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR09.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR10.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR11.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR12.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR13.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR14.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR15.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR16.png"));
        targeting.addFrame(loadImage("assets/Turret-Laser/LSR/LSR17.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 30;
        break;
    }
    if (firerate < firing.duration) firing.setDuration(firerate);
    targeting.setDuration(projectileSpeed);
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,0,-800,new StringPass() { public String passed() { return ("Upgrade your " + (the_player.selectedTower.type == 'r' ? "railgun" : (the_player.selectedTower.type == 'p' ? "plasmagun" : "freeze gun")) + " ID# " + the_player.selectedTower.ID); } },100, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING;
    } });
    for (int c = 0; c < 5; c++) {
      if (c>0) {
        if (type == 'l') bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Targeting Speed\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        else bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
        switch (type) {
          case 'r':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'p':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Plasma Damage\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'i':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Freeze Duration\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'l':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Laser Damage\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
        }
        upgradePanel.buttons.get(bulletDamageButtons[c]).grayed = true;
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeFireRate(); } });
        upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
      }
      else {
        if (type == 'l') bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Targeting Speed\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        else bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        switch (type) {
          case 'r':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'p':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Plasma Damage\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'i':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Freeze Duration\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'l':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Laser Damage\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
        }
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeFireRate(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    update_projectiles();
    if (state == State.RUNNING) {
      for (int i = burntcreatures.size()-1; i >= 0; i--) {
        BurntCreature b = burntcreatures.get(i);
        if (b.timer > 0) b.display();
        if (b.timer == 0) burntcreatures.remove(i);
      }
    }
    if (!inTransit && wasInTransit) { // create a body for a just-placed tower
      BodyDef bd = new BodyDef();
      bd.position.set(box2d.coordPixelsToWorld(new Vec2(0+xpos, 17*(radius/80)+ypos)));
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
      wasInTransit = false;
    }
    if (inTransit) {
      if (!wasInTransit) {
        if (targeting.timer < (((float)15/18)*targeting.duration) && poweringup) {
          poweringup = false;
          targeting.timer = targeting.duration-1;
        }
        box2d.destroyBody(tower_body); // destroy the body of a just-picked-up tower
      }
      wasInTransit = true;
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (tower t : the_player.towers) { //check for overlap with existing towers
        if (t != the_player.pickedup)
          if (sqrt((t.xpos-xpos)*(t.xpos-xpos)+(t.ypos-ypos)*(t.ypos-ypos)) <= radius*2)
            conflict = true;
      } // and check if the tower is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING) { // tower is placed and running
      energy += energyGain;  // gain energy
      if (targeting.timer >= (((float)15/18)*targeting.duration) && poweringup) {
        poweringup = false;
        fire_projectile();
      }
      if (!targeting.active()) {
        if (autofire) {
          autofirecounter++;
          // only autofire every nth time step where n is the fire rate
          if (autofirecounter == firerate) {
            switch (the_player.targetMode) {
              case 2:
                target = the_pop.closest(new Vec2(0,0));
                break;
              case 3:
                target = the_pop.highestAlpha();
                break;
              default:
                target = the_pop.vec_to_random_creature();
            }
            angle = atan2(target.y-ypos,target.x-xpos);
            fire();
            autofirecounter = 0;  // reset the counter
          }
        }
        else // user controlled: calculate the angle to the mouse pointer and point at the mouse
          //calculate the angle to the mouse pointer
          angle = atan2(mouse_y-ypos,mouse_x-xpos);//(ypos*((float)worldWidth/width)), x-(xpos*((float)worldWidth/width)));
      }
      else {
        if (autofirecounter < firerate-1) autofirecounter++;
      }
    }
  }

  void update_projectiles(){
    for (int i = projectiles.size() - 1; i >= 0; i--) {  // walk through particles to avoid missing one
      projectile p = projectiles.get(i);
      p.update();
      if(p.remove){
        p.killBody();  // remove the box2d body
        projectiles.remove(i);  // remove the projectile from the list
      }
    }
  }

  void display() {
    image(gunbase,xpos-(radius*((float)128/80)),ypos-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    
    if (firerate < firing.duration) firing.setDuration(firerate);
    if (projectileSpeed < targeting.duration) targeting.setDuration(projectileSpeed);
    
    if (laserfiretimer > 0) {
      float laserlength = sqrt(((xpos-target.x)*(xpos-target.x))+((ypos-target.y)*(ypos-target.y)));
      pushMatrix();
      translate(xpos,ypos,0);//cameraZ-zoomOffset);
      rotate(angle-(PI/2));
      rectMode(CORNER);
      noStroke();
      fill(255,240,240,255);
      rect(-6,0,12,laserlength);
      fill(255,0,0,255);
      rect(6,0,12,laserlength);
      rect(-18,0,12,laserlength);
      rectMode(CENTER);
      stroke(0);
      popMatrix();
      laserfiretimer--;
    }

    pushMatrix();
    translate(xpos, ypos);
    rotate(angle + HALF_PI);
    image(firing.currentFrame(),-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    popMatrix();
    
    if (targeting.active()) {
      pushMatrix();
        translate(target.x,target.y);
        rotate(targeting.currentFrameIndex() < 16 ? (float)targeting.currentFrameIndex()/5 : 3);
        image(targeting.currentFrame(),-512,-512);
      popMatrix();
    }

    for (projectile p: projectiles) { // display the active projectiles
      p.display();
    }

    // draw tower energy bar
    noFill();
    stroke(0);
    rect(xpos, ypos-30, 0.1*maxEnergy, 6);
    noStroke();
    fill(0, 0, 255);
    rect(xpos, ypos-30, 0.1*energy, 6);

    if (inTransit) {
    // draw the outline of the tower's box2D body
      pushMatrix();
      translate(xpos,ypos);
      fill(0, 0, 0, 0);
      if (conflict)stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
      for (tower t : the_player.towers) { // draw the outlines of all the other towers' bodies
        if (t != the_player.pickedup) {
          pushMatrix();
          translate(box2d.getBodyPixelCoord(t.tower_body).x, box2d.getBodyPixelCoord(t.tower_body).y);
          fill(0, 0, 0, 0);
          stroke(0);
          ellipse(0, 0, radius*2, radius*2);
          stroke(0);
          popMatrix();
        }
      }
    }
    else if (the_player.selectedTower != null && the_player.selectedTower.ID == ID) {
      pushMatrix();
      translate(box2d.getBodyPixelCoord(tower_body).x, box2d.getBodyPixelCoord(tower_body).y);
      fill(0, 0, 0, 0);
      stroke(255,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
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
    for (projectile p: projectiles)
      if (p != null)
        p.killBody();
    projectiles.clear();
  }

  /* Firing, dropping rocks, etc. uses up some of the tower's energy */
  
  void fire() {
    if (energy < ecost) return;
    if (type == 'l') {
      targeting.play();
      poweringup = true;
    }
    else {
      fire_projectile();
    }
  }

  void fire_projectile() {
    if (type == 'l') fire_laser();
    else {
      projectile p = new projectile(xpos, ypos, angle, dmg, type, projectileSpeed);
      projectiles.add(p);
      energy -= ecost;
      firing.play();
      if (playSound) {
        switch (type) {
          case 'r':
            soundtimer++;
            if (soundtimer == 3){
              soundtimer = 0;
              PlaySounds( "assets/Turret-Railgun/railgunfire01long.mp3" );
            }
            else PlaySounds( "assets/Turret-Railgun/railgunfire01slow_01.mp3" );
            break;
          case 'p':
            PlaySounds( "assets/Turret-Plasma/ricochet1.mp3");
            break;
          case 'i':
            PlaySounds( "assets/Turret-Freeze/Cannon.mp3");
            break;
          case 'l':
            PlaySounds( "assets/Turret-Laser/laser.mp3");
            break;
        }
      }
    }
  }
  
  void fire_laser() {
    laserfiretimer = projectileSpeed/18;
    if (laserfiretimer < 1) laserfiretimer = 1;
    if (playSound) PlaySounds( "assets/Turret-Laser/laser.mp3");
    float creatureradius;
    for (creature c : the_pop.swarm) {
      if (target.x < c.getPos().x + (c.getWidth()/2) && target.x > c.getPos().x - (c.getWidth()/2) 
          && target.y < c.getPos().y + (c.getWidth()/2) && target.y > c.getPos().y - (c.getWidth()/2)) {
        if (c.health <= dmg) burntcreatures.add(new BurntCreature(c));
        c.changeHealth(-1*dmg); // laser cannon ignores armor
      }
    }
  }

  void wave_fire() {
    if (type == 'l') return; // Laserguns can't wavefire. This is so much simpler.
    if (energy < 5) return;
    for (float a = 0; a < 2*PI ; a += ((2*PI)/20)) // postions of new projectiles are not at 0,0 to avoid collisions.
      projectiles.add(new projectile(xpos+(5*cos(a)), ypos+(5*sin(a)), a, dmg, type, projectileSpeed));
    energy -= 5;
    firing.play();
    if (playSound) {
      switch (type) {
        case 'r':
          PlaySounds( "assets/Turret-Railgun/railgunfire01long.mp3" );
          break;
        case 'p':
          PlaySounds( "assets/Turret-Plasma/ricochet1.mp3");
          break;
        case 'i':
          PlaySounds( "assets/Turret-Freeze/Cannon.mp3");
          break;
      }
    }
  }
  
  void upgradeBulletSpeed() {
    if (bulletSpeedUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(bulletSpeedUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(bulletSpeedUpgrades*3))*100);
    if (type == 'l') upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).button_text = "Targeting Speed\nX"+ (bulletSpeedUpgrades+2) + "\nPurchased!";
    else upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).button_text = "Bullet Speed\nX"+ (bulletSpeedUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletSpeedUpgrades < 4) {
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).grayed = false;
      if (type == 'l') upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).button_text = "Targeting Speed\nX"+ (bulletSpeedUpgrades+3) + "\n" + (((byte)1)<<((bulletSpeedUpgrades+1)*3)) + "00$";
      else upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).button_text = "Bullet Speed\nX"+ (bulletSpeedUpgrades+3) + "\n" + (((byte)1)<<((bulletSpeedUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds("assets/upgrade.mp3");
    
    bulletSpeedUpgrades++;
    
    if (type == 'l') projectileSpeed = round((float)baseProjectileSpeed/(bulletSpeedUpgrades+1));
    else projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
  }
  
  void upgradeBulletDamage() {
    if (bulletDamageUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(bulletDamageUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(bulletDamageUpgrades*3))*100);
    switch (type) {
      case 'r':
        upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Bullet Damage\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
        break;
      case 'p':
        upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Plasma Damage\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
        break;
      case 'i':
        upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Freeze Duration\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
        break;
      case 'l':
        upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Laser Damage\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
        break;
    }
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletDamageUpgrades < 4) {
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).grayed = false;
      switch (type) {
        case 'r':
          upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Bullet Damage\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
          break;
        case 'p':
          upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Plasma Damage\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
          break;
        case 'i':
          upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Freeze Duration\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
          break;
        case 'l':
          upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Laser Damage\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
          break;
      }
    }
    
    if (playSound) PlaySounds("assets/upgrade.mp3");
    
    bulletDamageUpgrades++;
    
    dmg = baseDamage*(bulletDamageUpgrades+1);
  }
  
  void upgradeFireRate() {
    if (fireRateUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(fireRateUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(fireRateUpgrades*3))*100);
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).button_text = "Rate of Fire\nX"+ (fireRateUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (fireRateUpgrades < 4) {
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).button_text = "Rate of Fire\nX"+ (fireRateUpgrades+3) + "\n" + (((byte)1)<<((fireRateUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds("assets/upgrade.mp3");
    
    fireRateUpgrades++;
    firerate = round((float)baseFirerate/(fireRateUpgrades+1));
    autofirecounter = 0;
  }
}
