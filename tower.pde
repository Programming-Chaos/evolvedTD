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
  float angle;    // angle of tower's main, auto-fire weapon
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  Animation firing;
  Animation targeting;
  PImage gunbase; // gun base
  int soundtimer;
  float radius = 50;
  int xpos; // x position of center of turret
  int ypos; // y position of center of turret
  int ecost; // per fire energy cost
  float health;
  float maxHealth = 500;
  int projectileSpeed;
  int baseProjectileSpeed;
  int bulletSpeedUpgrades = 0;
  int bulletSpeedButtons[] = new int[5];
  int dmg; // damage value, changed by turret type
  int baseDamage;
  int bulletDamageUpgrades = 0;
  int bulletDamageButtons[] = new int[5];
  int firerate; // autofire rate, lower values fire faster
  int baseFirerate;
  int fireRateUpgrades = 0;
  int fireRateButtons[] = new int[5];
  int shieldregentimer = 0;
  float shield;
  float maxShield;
  float baseMaxShield;
  int shieldUpgrades = 0;
  int shieldButtons[] = new int[5];
  float shieldRegen;
  float baseShieldRegen;
  int shieldRegenUpgrades = 0;
  int shieldRegenButtons[] = new int[5];
  int laserfiretimer = 0;
  String button1text;
  String button2text;
  String button3text;
  String button4text;
  String button5text;
  String nametext;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  boolean poweringup = false;
  boolean remove = false;
  Vec2 target;
  char type;
  int[] taste;
  Panel upgradePanel;
  structure parent;
  /* type is the turret type
   * r: default rail gun
   * l: plasmagun
   * i: freeze gun
   */
  Body tower_body;

  // constructor function, initializes the tower
  tower(char t, int id, structure prnt) {
    parent = prnt;
    ID = id;
    type = t;
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    projectiles = new ArrayList<projectile>();
    burntcreatures = new ArrayList<BurntCreature>();
    firing = new Animation();
    targeting = new Animation();
    angle = 0;
    soundtimer = 0;
    target = new Vec2(0,0);
    taste = new int[5]; // towers taste like food (for now)
    taste[0] = 100;
    taste[1] = 0;
    taste[2] = 0;
    taste[3] = 0;
    taste[4] = 50;

    xpos = round(mouse_x);
    ypos = round(mouse_y);

    baseMaxShield = 500000;
    baseShieldRegen = 1;
    button4text = "Shield Strength";
    button5text = "Shield Regen";
    maxShield = baseMaxShield*(shieldUpgrades+1);
    shield = maxShield;
    health = maxHealth;
    shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);

    switch (type) {
      case 'r': // railgun
        parent.moneyinvested += the_player.rcost;
        baseDamage = 80;
        baseFirerate = 25;
        baseProjectileSpeed = 100;
        gunbase = loadImage("assets/Turret-Railgun/Turbase03256.png");
        firing.addFrame(loadImage("assets/Turret-Railgun/RG001.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG005.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG004.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG003.png"));
        firing.addFrame(loadImage("assets/Turret-Railgun/RG002.png"));
        nametext = "Railgun";
        button1text = "Bullet Speed";
        button2text = "Bullet Damage";
        button3text = "Rate of Fire";
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        ecost = 10;
        break;
      case 'p': // plasma cannon
        parent.moneyinvested += the_player.pcost;
        baseDamage = 40;
        baseFirerate = 75;
        baseProjectileSpeed = 150;
        gunbase = loadImage("assets/Turret-Plasma/Turbase03256.png");
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap01-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap07-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap06-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap05-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap04-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap03-01.png"));
        firing.addFrame(loadImage("assets/Turret-Plasma/Capasitor Cannon/Cap02-01.png"));
        nametext = "Plasma Cannon";
        button1text = "Plasma Speed";
        button2text = "Plasma Damage";
        button3text = "Rate of Fire";
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        ecost = 30;
        break;
      case 'i': // freeze turret
        parent.moneyinvested += the_player.icost;
        baseDamage = 200; // functions as freeze duration since ice pellets don't do damage
        baseFirerate = 100;
        baseProjectileSpeed = 50;
        gunbase = loadImage("assets/Turret-Freeze/turret2-01.png");
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze01.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze02.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze03.png"));
        firing.addFrame(loadImage("assets/Turret-Freeze/Freeze04.png"));
        nametext = "Freeze Turret";
        button1text = "Ice Pellet Speed";
        button2text = "Freeze Duration";
        button3text = "Rate of Fire";
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        ecost = 20;
        break;
      case 'l': // laser artillery
        parent.moneyinvested += the_player.lcost;
        baseDamage = 70;
        baseFirerate = 150;
        baseProjectileSpeed = 100; // functions as targeting ticks since speed is instantaneous
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
        nametext = "Laser Artillery";
        button1text = "Targeting Speed";
        button2text = "Laser Damage";
        button3text = "Rate of Fire";
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        projectileSpeed = round((float)baseProjectileSpeed/(bulletSpeedUpgrades+1));
        ecost = 50;
        break;
      case 'g': // electron cloud generator
        parent.moneyinvested += the_player.gcost;
        baseDamage = 2; // damage per tick while in range, scales down linearly with further distance, increasing damage increases electrical range
        baseFirerate = 175;
        baseProjectileSpeed = 100; // functions as range as projectile speed is constant
        gunbase = loadImage("assets/Turret-Electron/Turbase03256.png");
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter1.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter2.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter3.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter4.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter5.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter6.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter7.png"));
        firing.addFrame(loadImage("assets/Turret-Electron/Animated turret/Tbuter8.png"));
        nametext = "Electron Cloud Generator";
        button1text = "Cloud Range";
        button2text = "Electrical Damage";
        button3text = "Rate of Fire";
        dmg = baseDamage*(bulletDamageUpgrades+1);
        firerate = round((float)baseFirerate/(fireRateUpgrades+1));
        projectileSpeed = baseProjectileSpeed*(bulletSpeedUpgrades+1);
        ecost = 80;
        break;
    }
    targeting.setDuration(projectileSpeed);
    if (firerate < firing.duration) firing.setDuration(firerate);
    upgradePanel = new Panel(2200,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,100,-800,new StringPass() { public String passed() { return ("Upgrade your " + nametext + " ID# " + the_player.selectedStructure.t.ID); } },80, false);
    upgradePanel.createTextBox(2200,200,0,-800,"",80, true);
    upgradePanel.createButton(200,200,-1000,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING;
    } });
    for (int c = 0; c < 5; c++) {
      if (c > 0) {
        bulletSpeedButtons[c] = upgradePanel.createButton(420, 280, -840, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
        bulletDamageButtons[c] = upgradePanel.createButton(420, 280, -420, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeBulletDamage(); } });
        upgradePanel.buttons.get(bulletDamageButtons[c]).grayed = true;
        fireRateButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeFireRate(); } });
        upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
        shieldButtons[c] = upgradePanel.createButton(420, 280, 420, 900-((5-c)*280),button4text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeShield(); } });
        upgradePanel.buttons.get(shieldButtons[c]).grayed = true;
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 840, 900-((5-c)*280),button5text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeShieldRegen(); } });
        upgradePanel.buttons.get(shieldRegenButtons[c]).grayed = true;
      }
      else {
        bulletSpeedButtons[c] = upgradePanel.createButton(420, 280, -840, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeBulletSpeed(); } });
        bulletDamageButtons[c] = upgradePanel.createButton(420, 280, -420, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeBulletDamage(); } });
        fireRateButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeFireRate(); } });
        shieldButtons[c] = upgradePanel.createButton(420, 280, 420, 900-((5-c)*280),button4text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeShield(); } });
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 840, 900-((5-c)*280),button5text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.t.upgradeShieldRegen(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    if (health <= 0) remove = true;
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
      bd.position.set(box2d.coordPixelsToWorld(new Vec2(xpos,ypos)));
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
        tower_body.setUserData(null);
        for (Fixture f = tower_body.getFixtureList(); f != null; f = f.getNext())
          f.setUserData(null);
        box2d.destroyBody(tower_body); // destroy the body of a just-picked-up tower
        wasInTransit = true;
      }
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (structure s : the_player.structures) { //check for overlap with existing structures
        if (s.ID != the_player.pickedup.ID) {
          if (s.type == 'b') {
            if (sqrt((s.f.xpos-xpos)*(s.f.xpos-xpos)+(s.f.ypos-ypos)*(s.f.ypos-ypos)) <= radius*2)
              conflict = true;
          }
          else if (sqrt((s.t.xpos-xpos)*(s.t.xpos-xpos)+(s.t.ypos-ypos)*(s.t.ypos-ypos)) <= radius*2)
            conflict = true;
        }
      } // and check if the tower is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING) { // tower is placed and running
      if (shieldregentimer == 5) {
        shieldregentimer = 0;
        if (shield < maxShield) shield += shieldRegen;
        if (shield > maxShield) shield = maxShield;
      }
      shieldregentimer++;
      if (laserfiretimer > 0) laserfiretimer--;
      energy += energyGain;  // gain energy
      if (targeting.timer >= (((float)14/18)*targeting.duration) && poweringup) {
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
                target = the_pop.closest(new Vec2(xpos,ypos));
                break;
              case 4:
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
      rect((-1*(bulletDamageUpgrades+1)),0,(2*(bulletDamageUpgrades+1)),laserlength);
      fill(255,0,0,255);
      rect((bulletDamageUpgrades+1),0,(2*(bulletDamageUpgrades+1)),laserlength);
      rect((-3*(bulletDamageUpgrades+1)),0,(2*(bulletDamageUpgrades+1)),laserlength);
      rectMode(CENTER);
      stroke(0);
      popMatrix();
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
    rect(xpos, ypos-62, 0.1*maxEnergy, 6);
    noStroke();
    fill(0, 0, 255);
    rect(xpos, ypos-62, 0.1*energy, 6);

    // draw tower health bar
    noFill();
    stroke(0);
    rect(xpos, ypos-56, 0.2*maxHealth, 6);
    noStroke();
    fill(100, 255, 100);
    rect(xpos, ypos-56, 0.2*health, 6);

    // draw tower shield bar
    noFill();
    stroke(0);
    rect(xpos, ypos-50, 0.2*maxShield, 6);
    noStroke();
    fill(20, 200, 255);
    rect(xpos, ypos-50, 0.2*shield, 6);

    if (inTransit) {
    // draw the outline of the tower's box2D body
      pushMatrix();
      translate(xpos,ypos);
      fill(0, 0, 0, 0);
      if (conflict) stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
      for (structure s : the_player.structures) { // draw the outlines of all the other structure's bodies
        if (s != the_player.pickedup) {
          pushMatrix();
          if (s.type == 'b') translate(box2d.getBodyPixelCoord(s.f.farm_body).x, box2d.getBodyPixelCoord(s.f.farm_body).y);
          else translate(box2d.getBodyPixelCoord(s.t.tower_body).x, box2d.getBodyPixelCoord(s.t.tower_body).y);
          fill(0, 0, 0, 0);
          stroke(0);
          ellipse(0, 0, radius*2, radius*2);
          stroke(0);
          popMatrix();
        }
      }
    }
    else if (the_player.selectedStructure != null && the_player.selectedStructure.ID == ID) {
      pushMatrix();
      translate(box2d.getBodyPixelCoord(tower_body).x, box2d.getBodyPixelCoord(tower_body).y);
      fill(0, 0, 0, 0);
      stroke(255,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
    }
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
      if (type == 'g') projectiles.add(new projectile(xpos+(40*cos(angle)), ypos+(40*sin(angle)), angle, dmg, type, projectileSpeed));
      else projectiles.add(new projectile(xpos, ypos, angle, dmg, type, projectileSpeed));
      energy -= ecost;
      firing.play();
      if (playSound) {
        switch (type) {
          case 'r':
            soundtimer++;
            if (soundtimer == 3){
              soundtimer = 0;
              PlaySounds( "Railgun_Long_01" );
            }
            else PlaySounds( "Railgun_Slow_01" );
            break;
          case 'p':
            soundtimer++;
            if (soundtimer == 3){
              soundtimer = 0;
              PlaySounds( "Ricochet_02" );
            }
            else PlaySounds( "Ricochet_01" );
            break;
          case 'i':
            PlaySounds( "Cannon_01" );
            break;
          case 'g':
            PlaySounds( "Cannon_01" );
            break;
        }
      }
    }
  }
  
  void fire_laser() {
    energy -= ecost;
    laserfiretimer = projectileSpeed/5;
    if (laserfiretimer > 5) laserfiretimer = 5;
    if (laserfiretimer < 1) laserfiretimer = 1;
    if (playSound) PlaySounds( "Laser_01" );
    float armoravg;
    for (creature c : the_pop.swarm) {
      if (target.x < c.getPos().x + (c.getWidth()/2) && target.x > c.getPos().x - (c.getWidth()/2) 
       && target.y < c.getPos().y + (c.getWidth()/2) && target.y > c.getPos().y - (c.getWidth()/2)) {
         armoravg = c.getArmorAvg();
        if (c.health <= dmg/armoravg) burntcreatures.add(new BurntCreature(c));
        c.changeHealth(round(-1*dmg/armoravg)); // laser cannon can be mitigated by creature's average armor
      }
    }
  }

  void wave_fire() {
    if (type == 'l') return; // Laserguns can't wavefire. This is so much simpler.
    if (type == 'g') return; // electron guns also can't wavefire
    if (energy < 5) return;
    for (float a = 0; a < 2*PI ; a += ((2*PI)/20)) // postions of new projectiles are not at 0,0 to avoid collisions.
      projectiles.add(new projectile(xpos+(5*cos(a)), ypos+(5*sin(a)), a, dmg, type, projectileSpeed));
    energy -= 5;
    firing.play();
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
        case 'g':
          
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
    parent.moneyinvested += ((((byte)1)<<(bulletSpeedUpgrades*3))*100);
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).button_text = button1text + "\nX"+ (bulletSpeedUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletSpeedUpgrades < 4) {
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).button_text = button1text + "\nX"+ (bulletSpeedUpgrades+3) + "\n" + (((byte)1)<<((bulletSpeedUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds("Upgrade_01");
    
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
    parent.moneyinvested += ((((byte)1)<<(bulletDamageUpgrades*3))*100);
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = button2text + "\nX"+ (bulletDamageUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletDamageUpgrades < 4) {
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = button2text + "\nX"+ (bulletDamageUpgrades+3) + "\n" + (((byte)1)<<((bulletDamageUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
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
    parent.moneyinvested += ((((byte)1)<<(fireRateUpgrades*3))*100);
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).button_text = button3text + "\nX"+ (fireRateUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (fireRateUpgrades < 4) {
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).button_text = button3text + "\nX"+ (fireRateUpgrades+3) + "\n" + (((byte)1)<<((fireRateUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    fireRateUpgrades++;
    firerate = round((float)baseFirerate/(fireRateUpgrades+1));
    autofirecounter = 0;
  }
  
  void upgradeShield() {
    if (shieldUpgrades > 4) return;
    if (the_player.money < ((((byte)1)<<(shieldUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(shieldUpgrades*3))*100);
    parent.moneyinvested += ((((byte)1)<<(shieldUpgrades*3))*100);
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).button_text = button4text + "\nX"+ (shieldUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldUpgrades < 4) {
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).button_text = button4text + "\nX"+ (shieldUpgrades+3) + "\n" + (((byte)1)<<((shieldUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds("Upgrade_01");
    
    shieldUpgrades++;
    
    float shielddifference = (-1*maxShield);
    maxShield = baseMaxShield*(shieldUpgrades+1);
    shielddifference += maxShield;
    shield += shielddifference;
  }
  
  void upgradeShieldRegen() {
    if (shieldRegenUpgrades > 4) return;
    if (the_player.money < ((((byte)1)<<(shieldRegenUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(shieldRegenUpgrades*3))*100);
    parent.moneyinvested += ((((byte)1)<<(shieldRegenUpgrades*3))*100);
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).button_text = button5text + "\nX"+ (shieldRegenUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldRegenUpgrades < 4) {
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).button_text = button5text + "\nX"+ (shieldRegenUpgrades+3) + "\n" + (((byte)1)<<((shieldRegenUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    shieldRegenUpgrades++;
    
    shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
  }
}
