class player {
  ArrayList<tower> towers;
  Panel playerPanel;
  Panel statsPanel;
  Panel newpanel;
  Panel upgradePanel;
  Panel hudPanel;
  Panel towerPanel;
  int bulletSpeedButtons[] = new int[5];
  int bulletSpeedUpgrades = 0;
  int bulletDamageButtons[] = new int[5];
  int bulletDamageUpgrades = 0;
  int fireRateButtons[] = new int[5];
  int fireRateUpgrades = 0;
  int money = 0;
  int moneyGain = 1; // money per 40 ticks
  int currentMoneyTick;
  int numrailguns;
  int numflamethrowers;
  
  Panel testpanel;
  
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  creature selectedCreature;

  player() {
    towers = new ArrayList<tower>();
    numrailguns = 0;
    numflamethrowers = 0;
    
    testpanel = new Panel(400,400,-1000,0,true);
    testpanel.createTextBox(400,200,0,-100,"THIS is a textbox!",40,true);
    testpanel.createButton(300,100,0,100,"Yay BUTTON",30,0,0,0,new ButtonPress() { public void pressed() { println("button has been pressed!!"); } });
    testpanel.enabled = false;
    
    playerPanel = new Panel(500,420,980,-1020,true);
    playerPanel.createTextBox(480,50,0,-180,new StringPass() { public String passed() { return ("Resources: " + (int)resources); } },40);
    playerPanel.createTextBox(480,50,0,-100,new StringPass() { public String passed() { return ("Generation: " + generation); } },40);
    playerPanel.createTextBox(480,50,0,-20,new StringPass() { public String passed() { return ("Time left: " + (timepergeneration - timesteps)); } },40);
    playerPanel.createButton(350,100,0,110,"Wave Fire",50,new ButtonPress() { public void pressed() { wave_fire(); } });
    
    statsPanel = new Panel(500,520,980,1020-200,false);//-200 so it's not cut off the bottom of some people's screens
    statsPanel.setupTextBoxList(20,10,50,40);
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Creature: " + selectedCreature.num); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Health: " + selectedCreature.health + " / " + selectedCreature.maxHealth + " +" + selectedCreature.health_regen); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Fitness: " + selectedCreature.fitness); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Max speed: " + (int)selectedCreature.maxMovementSpeed); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Time in water: " + selectedCreature.time_in_water); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Time on land: " + selectedCreature.time_on_land); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Scent strength: " + selectedCreature.scentStrength); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Reproduction energy: " + (int)selectedCreature.energy_reproduction); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Locomotion energy: " + (int)selectedCreature.energy_locomotion); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Health energy: " + (int)selectedCreature.energy_health); } });

    upgradePanel = new Panel(2000,1800,0,0,false, 255);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,0,-800,"Upgrade your defenses",100, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() { upgradePanel.enabled = false; state = State.RUNNING; } });
    for (int c = 0; c < 5; c++) {
      
      if (c>0) {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\n+"+ (c+1) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletSpeed(); } });
        upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
        bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\n+"+ (c+1) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletDamage(); } });
        upgradePanel.buttons.get(bulletDamageButtons[c]).grayed = true;
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\n+"+ (c+1) + "\n(Locked)", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeFireRate(); } });
        upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
      }
      else {
        bulletSpeedButtons[c] = upgradePanel.createButton(400, 280, -600, 900-((5-c)*280),"Bullet Speed\n+"+ (c+1) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletSpeed(); } });
        bulletDamageButtons[c] = upgradePanel.createButton(400, 280, 0, 900-((5-c)*280),"Bullet Damage\n+"+ (c+1) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletDamage(); } });
        fireRateButtons[c] = upgradePanel.createButton(400, 280, 600, 900-((5-c)*280),"Rate of Fire\n+"+ (c+1) + "\n100$", 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeFireRate(); } });
      }
    }
    
    hudPanel = new Panel(2500,100,0,-1200,false,50);
    hudPanel.createTextBox(20, 20, new StringPass() { String passed() { return ("Currency: " + money); } }, 50);

    towerPanel = new Panel(2500, 300, 0, 1100, true);
    towerPanel.createButton(300, 300, -1100, 0, "Railgun", 45, 0, 0, 0, new ButtonPress() {public void pressed() { if(numrailguns<13)the_player.towers.add(new tower(((int)(500*cos(numrailguns*(PI/6)))), ((int)(500*sin(numrailguns*(PI/6)))), 'r')); } });
    towerPanel.createButton(300, 300, -800, 0, "Flamethrower", 45, 200, 0, 0, new ButtonPress() {public void pressed() { if(numflamethrowers<12)the_player.towers.add(new tower(((int)(500*cos(numflamethrowers*(PI/6)+(PI/12)))), ((int)(500*sin(numflamethrowers*(PI/6)+(PI/12)))), 'f')); } });

    resources = 0;
    resourceGain = 0.1;
    selectedCreature = null;
  }

  void display() {
    if (selectedCreature != null) {
      Vec2 pos = box2d.getBodyPixelCoord(selectedCreature.body);
      cameraX = int(pos.x);
      cameraY = int(pos.y);
      statsPanel.enabled = true;
    }
    else statsPanel.enabled = false;
    
    for (int i = towers.size() - 1; i >= 0; i--)  // walk through the towers
      towers.get(i).display();  // display them all
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).display();
  }

  void update() {
    if (state == State.RUNNING) {
      resources += resourceGain;
      currentMoneyTick++;
      if (currentMoneyTick == 40) {
        currentMoneyTick = 0;
        money += moneyGain;
      }
    }
    // walk through the towers
    for (int i = towers.size() - 1; i >= 0; i--)
      towers.get(i).update();   // update them
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).update();
  }

  void mouse_pressed() {
    // check if the mouse was pressed in the player panel
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).mouse_pressed();
  }

  void wave_fire(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.wave_fire();
    }
  }

  void next_generation(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.next_generation();
    }
  }

  void upgradeBulletSpeed() {
    if (bulletSpeedUpgrades > 4)return;
    if (money < (0)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).button_text = "Bullet Speed\n+"+ (bulletSpeedUpgrades+1) + "\nPurchased!";
    upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletSpeedUpgrades < 4) {
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletSpeedButtons[bulletSpeedUpgrades+1]).button_text = "Bullet Speed\n+"+ (bulletSpeedUpgrades+2) + "\n" + (((byte)1)<<(bulletSpeedUpgrades+1)) + "00$";
    }
    bulletSpeedUpgrades++;
  }
  
  void upgradeBulletDamage() {
    if (bulletDamageUpgrades > 4)return;
    if (money < (0)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).button_text = "Bullet Damage\n+"+ (bulletDamageUpgrades+1) + "\nPurchased!";
    upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (bulletDamageUpgrades < 4) {
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(bulletDamageButtons[bulletDamageUpgrades+1]).button_text = "Bullet Damage\n+"+ (bulletDamageUpgrades+2) + "\n" + (((byte)1)<<(bulletDamageUpgrades+1)) + "00$";
    }
    bulletDamageUpgrades++;
  }
  
  void upgradeFireRate() {
    if (fireRateUpgrades > 4)return;
    if (money < (0)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).button_text = "Fire Rate\n+"+ (fireRateUpgrades+1) + "\nPurchased!";
    upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (fireRateUpgrades < 4) {
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(fireRateButtons[fireRateUpgrades+1]).button_text = "Fire Rate\n+"+ (fireRateUpgrades+2) + "\n" + (((byte)1)<<(fireRateUpgrades+1)) + "00$";
    }
    fireRateUpgrades++;
  }
}
