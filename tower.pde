class tower {
  int ID;
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int energyGain;       // energy gain per timestep
  int maxEnergy = 1000; // max energy the tower can have
  ArrayList<projectile> projectiles;  // list of active projectiles
  float angle;    // angle of tower's main, auto-fir weapon
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  ArrayList<PImage> gunframes;
  PImage gunbase; // gun base
  boolean showgun = true; // show base gun image
  boolean showgunalt = false; // show alternate gun image
  int imagetimer; // timer for alternating gun images
  int animationrate;
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
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
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
    gunframes = new ArrayList<PImage>();
    angle = 0;
    soundtimer = 0;

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
        gunframes.add(loadImage("assets/Turret-Railgun/RG001.png"));
        gunframes.add(loadImage("assets/Turret-Railgun/RG002.png"));
        gunframes.add(loadImage("assets/Turret-Railgun/RG003.png"));
        gunframes.add(loadImage("assets/Turret-Railgun/RG004.png"));
        gunframes.add(loadImage("assets/Turret-Railgun/RG005.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 10;
        break;
      case 'p':
        baseDamage = 100;
        baseFirerate = 75;
        baseProjectileSpeed = 150;
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        gunbase = loadImage("assets/Turret-Plasma/Turret base 03-01.png");
        gunframes.add(loadImage("assets/Turret-Plasma/PlasmaGun01-01.png"));
        gunframes.add(loadImage("assets/Turret-Plasma/PlasmaGun01-01.png"));
        gunframes.add(loadImage("assets/Turret-Plasma/PlasmaGun02-01.png"));
        gunframes.add(loadImage("assets/Turret-Plasma/PlasmaGun02-01.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 50;
        break;
      case 'i':
        baseDamage = 200;
        baseFirerate = 100;
        baseProjectileSpeed = 50;
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        gunbase = loadImage("assets/Turret-Freeze/turret2-01.png");
        gunframes.add(loadImage("assets/Turret-Freeze/Freeze01.png"));
        gunframes.add(loadImage("assets/Turret-Freeze/Freeze02.png"));
        gunframes.add(loadImage("assets/Turret-Freeze/Freeze03.png"));
        gunframes.add(loadImage("assets/Turret-Freeze/Freeze04.png"));
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        ecost = 30;
        break;
    }
    animationrate = (3*gunframes.size()); // at most 3 ticks per frame
    if (firerate < animationrate) animationrate = firerate;
    imagetimer = animationrate-1;
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,0,-800,new StringPass() { public String passed() { return ("Upgrade your " + (the_player.selectedTower.type == 'r' ? "railgun" : (the_player.selectedTower.type == 'p' ? "plasmagun" : "freeze gun")) + " ID# " + the_player.selectedTower.ID); } },100, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING;
    } });
    for (int c = 0; c < 5; c++) {
      if (c>0) {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
        switch (type) {
          case 'r':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'p':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Plasma Damage\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'i':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Freeze Duration\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
        }
        upgradePanel.buttons.get(bulletDamageButtons[c]).grayed = true;
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\nX"+ (c+2) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeFireRate(); } });
        upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
      }
      else {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        switch (type) {
          case 'r':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'p':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Plasma Damage\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
          case 'i':
            bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Freeze Duration\nX"+ (c+2) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
            break;
        }
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
    image(gunbase,xpos-(radius*((float)128/80)),ypos-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    animationrate = (3*gunframes.size()); // at most 3 ticks per frame
    if (firerate < animationrate) animationrate = firerate;
    if (imagetimer < animationrate-1) imagetimer++;
    int index = ((((int)(imagetimer/((float)animationrate/gunframes.size())))+1)%gunframes.size());
    PImage currentgun = gunframes.get(index);

    pushMatrix();
    translate(xpos, ypos, 0);
    rotate(angle + HALF_PI);
    image(currentgun,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
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

  void fire_projectile() {
    if (energy < ecost) return;
    projectile p = new projectile(xpos, ypos, angle, dmg, type, projectileSpeed);
    projectiles.add(p);
    energy -= ecost;
    imagetimer = 0;
    switch (type) {
      case 'r':
        soundtimer++;
        if (soundtimer == 3){
          soundtimer = 0;
          if (playSound) PlaySounds( "Railgun_Long_01" ); //rail long
        }
        else if (playSound) PlaySounds( "Railgun_Slow_01" ); //rail slow
        break;
      case 'p':
        if (playSound) PlaySounds( "Ricochet_01" ); //ricochet
        break;
      case 'i':
        if (playSound) PlaySounds( "Cannon_01" ); //cannon
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
      switch (type) {
        case 'r':
          PlaySounds( "Railgun_Long_01" ); //rail long
          break;
        case 'p':
          PlaySounds( "Ricochet_01" ); //ricochet
          break;
        case 'i':
          PlaySounds( "Cannon_01" ); //cannon
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
      }
    }
    
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
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).button_text = "Fire Rate\nX"+ (fireRateUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (fireRateUpgrades < 4) {
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).button_text = "Fire Rate\nX"+ (fireRateUpgrades+3) + "\n" + (((byte)1)<<((fireRateUpgrades+1)*3)) + "00$";
    }
    
    fireRateUpgrades++;
    firerate = round((float)baseFirerate/(fireRateUpgrades+1));
    autofirecounter = 0;
  }
}
