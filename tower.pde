class tower {
  int ID;
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
  int xpos; // x position of center of turret
  int ypos; // y position of center of turret
  int dmg; // damage value, changed by turret type
  int baseDamageRailgun = 20;
  int baseDamageFlamethrower = 200;
  int firerate; // autofire rate, lower values fire faster
  int baseFirerate;
  int projectileSpeed;
  int baseProjectileSpeed = 100;
  int ecost; // per fire energy cost
  int bulletSpeedUpgrades = 0;
  int bulletDamageUpgrades = 0;
  int fireRateUpgrades = 0;
  int bulletSpeedButtons[] = new int[5];
  int bulletDamageButtons[] = new int[5];
  int fireRateButtons[] = new int[5];
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  char type;
  Panel upgradePanel;
  /* type is the turret type
   * r: default rail gun
   * f: flamethrower
   */
  Body tower_body;

  // constructor function, initializes the tower
  tower(char t, int id) {
    ID = id;
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    projectiles = new ArrayList<projectile>();
    angle = 0;
    imagetimer = 0;
    soundtimer = 0;
    projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);

    xpos = round(mouse_x);
    ypos = round(mouse_y);
    type = t;

    switch (type){
      case 'r':
        baseFirerate = 25;
        gunbase = loadImage("assets/Tower_base_02.png");
        gun = loadImage("assets/RailGun-01.png");
        gunalt = loadImage("assets/RailGun-a-01.png");
        dmg = baseDamageRailgun*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 10;
        break;
      case 'f':
        baseFirerate = 75;
        gun = loadImage("assets/FlameThrower01-01.png");
        gunalt = loadImage("assets/FlameThrower02-01.png");
        gunbase = loadImage("assets/Turbase03256.png");
        dmg = baseDamageFlamethrower*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 50;
        break;
    }
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,0,-800,new StringPass() { public String passed() { return ("Upgrade your " + (the_player.selectedTower.type == 'r' ? "railgun" : "flamethrower") + " ID# " + the_player.selectedTower.ID); } },100, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING;
    } });
    for (int c = 0; c < 5; c++) {
      
      if (c>0) {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
        bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
        upgradePanel.buttons.get(bulletDamageButtons[c]).grayed = true;
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeFireRate(); } });
        upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
      }
      else {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeFireRate(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    update_projectiles();
    if (!inTransit && wasInTransit) {
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
      if (!wasInTransit)
        box2d.destroyBody(tower_body);
      wasInTransit = true;
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
          fire_projectile();
          autofirecounter = 0;  // reset the counter
        }
      }
      else // user controlled: calculate the angle to the mouse pointer and point at the mouse
        //calculate the angle to the mouse pointer
        angle = atan2(mouse_y-ypos,mouse_x-xpos);//(ypos*((float)worldWidth/width)), x-(xpos*((float)worldWidth/width)));
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
    rotate(angle + HALF_PI);
    if(showgun)image(gun,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    if(showgunalt)image(gunalt,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    popMatrix();

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
    }
    else if (the_player.placing) {
      for (tower t : the_player.towers) {
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
        killBody();
    projectiles.clear();
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

  void upgradeBulletSpeed() {
    if (bulletSpeedUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(bulletSpeedUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(bulletSpeedUpgrades*3))*100);
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).button_text = "Bullet Speed\nX"+ (bulletSpeedUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletSpeedUpgrades < 4) {
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).button_text = "Bullet Speed\nX"+ (bulletSpeedUpgrades+3) + "\n" + (((byte)1)<<((bulletSpeedUpgrades+1)*3)) + "00$";
    }
    
    bulletSpeedUpgrades++;
    
    projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
  }
  
  void upgradeBulletDamage() {
    if (bulletDamageUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(bulletDamageUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(bulletDamageUpgrades*3))*100);
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Bullet Damage\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletDamageUpgrades < 4) {
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Bullet Damage\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
    }
    
    bulletDamageUpgrades++;
    
    switch (type) {
      case 'r':
        dmg = baseDamageRailgun*(bulletDamageUpgrades+1);
        break;
      case 'f':
        dmg = baseDamageFlamethrower*(bulletDamageUpgrades+1);
        break;
      }
  }
  
  void upgradeFireRate() {
    if (fireRateUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(fireRateUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(fireRateUpgrades*3))*100);
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).button_text = "Fire Rate\nX"+ (fireRateUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (fireRateUpgrades < 4) {
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).button_text = "Fire Rate\nX"+ (fireRateUpgrades+3) + "\n" + (((byte)1)<<((fireRateUpgrades+1)*3)) + "00$";
    }
    
    fireRateUpgrades++;
    
    switch (type) {
      case 'r':
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        break;
      case 'f':
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        break;
    }
    autofirecounter = 0;
  }
}
