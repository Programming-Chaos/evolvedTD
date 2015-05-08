class structure {
  int ID;
  char type;
  tower t;
  farm f;
  int moneyinvested;
  
  structure(char tp, int id) {
    moneyinvested = 0;
    ID = id;
    switch (tp) {
      case 'b':
      case 'd':
        type = 'f';
        f = new farm(tp, ID, this);
        break;
      case 'r':
      case 'p':
      case 'i':
      case 'l':
      case 'g':
        type = 't';
        t = new tower(tp, ID, this);
        break;
    }
  }
}

class farm {
  int ID;
  float angle; // angle of farm's production rotation platform
  PImage base; // farm base
  PImage rotator; // farm rotation platform
  Animation mining;
  float radius = 50;
  int xpos; // x position of center of farm
  int ypos; // y position of center of farm
  float health;
  float maxHealth = 100;
  int productionSpeed;
  int baseProductionSpeed;
  int productionSpeedUpgrades = 0;
  int productiontimer = 0;
  int productionSpeedButtons[] = new int[5];
  float shield;
  float maxShield;
  float baseMaxShield;
  int shieldUpgrades = 0;
  int shieldButtons[] = new int[5];
  float shieldRegen;
  float baseShieldRegen;
  int shieldRegenUpgrades = 0;
  int shieldRegenButtons[] = new int[5];
  String button1text;
  String button2text;
  String button3text;
  String nametext;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  boolean remove = false;
  char type;
  int[] taste;
  Panel upgradePanel;
  structure parent;
  /* type is the turret type
   * r: default rail gun
   * l: plasmagun
   * i: freeze gun
   */
  Body farm_body;

  // constructor function, initializes the tower
  farm(char t, int id, structure prnt) {
    type = t;
    parent = prnt;
    ID = id;
    mining = new Animation();
    angle = 0;
    taste = new int[5]; // bioreactors taste like food (for now)
    taste[0] = 100;
    taste[1] = 0;
    taste[2] = 0;
    taste[3] = 0;
    taste[4] = 50;

    xpos = round(mouse_x);
    ypos = round(mouse_y);

    switch (type) {
      case 'b':
        parent.moneyinvested += the_player.bcost;
        baseProductionSpeed = 1;
        baseMaxShield = 50;
        baseShieldRegen = 1;
        base = loadImage("assets/bioreactor/BioGen Base-01.png");
        rotator = loadImage("assets/bioreactor/BioGen Top-01.png");
        nametext = "Bioreactor";
        button1text = "Production Speed";
        button2text = "Shield Strength";
        button3text = "Shield Regeneration";
        maxShield = baseMaxShield*(shieldUpgrades+1);
        shield = maxShield;
        health = maxHealth;
        productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
        shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
        break;
      case 'd':
        parent.moneyinvested += the_player.dcost;
        baseProductionSpeed = 1;
        baseMaxShield = 50;
        baseShieldRegen = 1;
        mining.addFrame(loadImage("assets/Drill/Drill_01.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_02.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_03.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_04.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_05.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_06.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_07.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_08.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_09.png"));
        mining.addFrame(loadImage("assets/Drill/Drill_10.png"));
        mining.setDuration(6-productionSpeedUpgrades, true);
        nametext = "Drill";
        button1text = "Mining Speed";
        button2text = "Shield Strength";
        button3text = "Shield Regeneration";
        maxShield = baseMaxShield*(shieldUpgrades+1);
        shield = maxShield;
        health = maxHealth;
        productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
        shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
        break;
    }
    
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,100,-800,new StringPass() { public String passed() { return ("Upgrade your " + nametext + " ID# " + the_player.selectedStructure.f.ID); } },80, false);
    upgradePanel.createTextBox(2000,200,0,-800,"",80, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() {public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING;
    } });
    for (int c = 0; c < 5; c++) {
      if (c > 0) {
        productionSpeedButtons[c] = upgradePanel.createButton(420, 280, -600, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeProductionSpeed(); } });
        upgradePanel.buttons.get(productionSpeedButtons[c]).grayed = true;
        shieldButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShield(); } });
        upgradePanel.buttons.get(shieldButtons[c]).grayed = true;
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 600, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShieldRegen(); } });
        upgradePanel.buttons.get(shieldRegenButtons[c]).grayed = true;
      }
      else {
        productionSpeedButtons[c] = upgradePanel.createButton(420, 280, -600, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeProductionSpeed(); } });
        shieldButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShield(); } });
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 600, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShieldRegen(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    if (health <= 0) remove = true;
    if (!inTransit && wasInTransit) { // create a body for a just-placed farm
      if (type == 'd') if (!mining.looping) mining.beginLooping();
      BodyDef bd = new BodyDef();
      bd.position.set(box2d.coordPixelsToWorld(new Vec2(xpos,ypos)));
      bd.type = BodyType.STATIC;
      bd.linearDamping = 0.9;
      farm_body = box2d.createBody(bd);
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
      if (type == 'd') if (mining.looping) mining.reset();
      if (!wasInTransit) {
        farm_body.setUserData(null);
        for (Fixture f = farm_body.getFixtureList(); f != null; f = f.getNext())
          f.setUserData(null);
        box2d.destroyBody(farm_body); // destroy the body of a just-picked-up farm
      }
      wasInTransit = true;
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (structure s : the_player.structures) { //check for overlap with existing structures
        if (s != the_player.pickedup) {
          if (s.type == 'f') {
            if (sqrt((s.f.xpos-xpos)*(s.f.xpos-xpos)+(s.f.ypos-ypos)*(s.f.ypos-ypos)) <= radius*2)
              conflict = true;
          }
          else if (sqrt((s.t.xpos-xpos)*(s.t.xpos-xpos)+(s.t.ypos-ypos)*(s.t.ypos-ypos)) <= radius*2)
            conflict = true;
        }
      } // and check if the farm is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING) { // farm is placed and running
      if (productiontimer == 5) {
        productiontimer = 0;
        the_player.money += (productionSpeed*(generation+1)); // this is the point of farms, right now
        if (shield < maxShield) shield += shieldRegen;
        if (shield > maxShield) shield = maxShield;
      }
      productiontimer++;
      angle += (productionSpeed*PI/32);
      if (angle > 2*PI) angle -= 2*PI;
    }
  }

  void display() {
    if (type == 'd') image(mining.currentFrame(),xpos-((float)radius*1.15),ypos-((float)radius*1.15),((float)radius*1.15)*2,((float)radius*1.15)*2);
    else image(base,xpos-((float)radius*1.15),ypos-((float)radius*1.15),((float)radius*1.15)*2,((float)radius*1.15)*2);

    pushMatrix();
    translate(xpos, ypos);
    rotate(angle);
    if (type != 'd') image(rotator,-1*((float)radius*1.15),-1*((float)radius*1.15), ((float)radius*1.15)*2, ((float)radius*1.15)*2);
    popMatrix();

    // draw farm health bar
    noFill();
    stroke(0);
    rect(xpos, ypos-56, 0.2*maxHealth, 6);
    noStroke();
    fill(100, 255, 100);
    rect(xpos, ypos-56, 0.2*health, 6);

    // draw farm shield bar
    noFill();
    stroke(0);
    rect(xpos, ypos-50, 0.2*maxShield, 6);
    noStroke();
    fill(20, 200, 255);
    rect(xpos, ypos-50, 0.2*shield, 6);

    if (inTransit) {
    // draw the outline of the farm's box2D body
      pushMatrix();
      translate(xpos,ypos);
      fill(0, 0, 0, 0);
      if (conflict)stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
      for (structure s : the_player.structures) { // draw the outlines of all the other structure's bodies
        if (s != the_player.pickedup) {
          pushMatrix();
          if (s.type == 'f') translate(box2d.getBodyPixelCoord(s.f.farm_body).x, box2d.getBodyPixelCoord(s.f.farm_body).y);
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
      translate(box2d.getBodyPixelCoord(farm_body).x, box2d.getBodyPixelCoord(farm_body).y);
      fill(0, 0, 0, 0);
      stroke(255,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
    }
  }
  
  void upgradeProductionSpeed() {
    if (productionSpeedUpgrades > 4) return;
    if (the_player.money < ((((byte)1)<<(productionSpeedUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(productionSpeedUpgrades*3))*100);
    parent.moneyinvested += ((((byte)1)<<(productionSpeedUpgrades*3))*100);
    upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades]).button_text = button1text + "\nX"+ (productionSpeedUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (productionSpeedUpgrades < 4) {
      upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades+1]).button_text = button1text + "\nX"+ (productionSpeedUpgrades+3) + "\n" + (((byte)1)<<((productionSpeedUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    productionSpeedUpgrades++;
    
    if (type == 'd') mining.setDuration(6-productionSpeedUpgrades, true);
    productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
  }
  
  void upgradeShield() {
    if (shieldUpgrades > 4) return;
    if (the_player.money < ((((byte)1)<<(shieldUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(shieldUpgrades*3))*100);
    parent.moneyinvested += ((((byte)1)<<(shieldUpgrades*3))*100);
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).button_text = button2text + "\nX"+ (shieldUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldUpgrades < 4) {
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).button_text = button2text + "\nX"+ (shieldUpgrades+3) + "\n" + (((byte)1)<<((shieldUpgrades+1)*3)) + "00$";
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
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).button_text = button3text + "\nX"+ (shieldRegenUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldRegenUpgrades < 4) {
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).button_text = button3text + "\nX"+ (shieldRegenUpgrades+3) + "\n" + (((byte)1)<<((shieldRegenUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    shieldRegenUpgrades++;
    
    shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
  }
}
