class structure {
  int ID;
  char type;
  tower t;
  farm f;
  
  structure(char tp, int id) {
    ID = id;
    switch (type) {
      case 'b':
        type = 'b'
        f = new farm(ID);
        break;
      case 'r':
      case 'p':
      case 'i':
      case 'l':
      case 'g':
        type = 't';
        t = new tower(type, ID);
        break;
    }
  }
}

class farm {
  int ID;
  PImage base; // gun base
  float radius = 50;
  int xpos; // x position of center of farm
  int ypos; // y position of center of farm
  int shield;
  int baseShield;
  float health;
  float maxHealth = 100;
  int productionSpeed;
  int baseProductionSpeed;
  int shieldUpgrades = 0;
  int productionSpeedUpgrades = 0;
  int shieldButtons[] = new int[5];
  int productionSpeedButtons[] = new int[5];
  String button1text;
  String button2text;
  String nametext;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  Panel upgradePanel;
  /* type is the turret type
   * r: default rail gun
   * l: plasmagun
   * i: freeze gun
   */
  Body farm_body;

  // constructor function, initializes the tower
  bioreactor(int id) {
    ID = id;

    xpos = round(mouse_x);
    ypos = round(mouse_y);

    baseShield = 50;
    baseProductionSpeed = 5;
    base = loadImage("assets/bioreactor/Farm Base model-01.png");
    nametext = "Bioreactor";
    button1text = "Shield Strength";
    button2text = "Production Speed";
    shield = baseShield*(shieldUpgrades+1);
    productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,100,-800,new StringPass() { public String passed() { return ("Upgrade your " + nametext + " ID# " + the_player.selectedTower.ID); } },80, false);
    upgradePanel.createTextBox(2000,200,0,-800,"",80, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING; } });
    for (int c = 0; c < 5; c++) {
      if (c > 0) {
        shieldButtons[c] = upgradePanel.createButton(400, 280, -400, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(shieldButtons[c]).grayed = true;
        productionSpeedButtons[c] = upgradePanel.createButton(400, 280, 400, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
        upgradePanel.buttons.get(productionSpeedButtons[c]).grayed = true;
      }
      else {
        shieldButtons[c] = upgradePanel.createButton(400, 280, -400, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletSpeed(); } });
        productionSpeedButtons[c] = upgradePanel.createButton(400, 280, 400, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedTower.upgradeBulletDamage(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    if (!inTransit && wasInTransit) { // create a body for a just-placed farm
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
      farm_body.createFixture(fd);
      farm_body.setUserData(this);
      wasInTransit = false;
    }
    if (inTransit) {
      if (!wasInTransit)
        box2d.destroyBody(tower_body); // destroy the body of a just-picked-up farm
      wasInTransit = true;
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (structure s : the_player.structures) { //check for overlap with existing structures
        if (s != the_player.pickedup) {
          if (s.type == 'b')
            if (sqrt((s.f.xpos-xpos)*(s.f.xpos-xpos)+(s.f.ypos-ypos)*(s.f.ypos-ypos)) <= radius*2)
              conflict = true;
          else if (sqrt((s.t.xpos-xpos)*(s.t.xpos-xpos)+(s.t.ypos-ypos)*(s.t.ypos-ypos)) <= radius*2)
            conflict = true;
        }
      } // and check if the farm is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING) { // farm is placed and running
      
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
}
