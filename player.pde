class player {
  ArrayList<tower> towers;
  Panel playerPanel;
  Panel statsPanel;
  Panel newpanel;
  Panel upgradePanel;
  Panel guiPanel;
  int bulletSpeedButtons[] = new int[5];
  int bulletSpeedUpgrades = 0;
  int bulletWeightButtons[] = new int[5];
  int bulletWeightUpgrades = 0;
  int fireRateButtons[] = new int[5];
  int fireRateUpgrades = 0;
  int money = 0;
  int moneyGain = 1; // money per 40 ticks
  int currentMoneyTick;
  
  Panel testpanel;
  
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  creature selectedCreature;

  player() {
    towers = new ArrayList<tower>();
    
    testpanel = new Panel(400,400,-1000,0,true);
    testpanel.createTextBox(400,200,0,-100,"THIS is a textbox!",40,true);
    testpanel.createButton(300,100,0,100,"Yay BUTTON",30,0,0,0,new ButtonPress() { public void pressed() { println("button has been pressed!!"); } });
    //testpanel.enabled = false;
    
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
    for (int c = 0; c < 5; c++) {
      bulletSpeedButtons[c] = upgradePanel.createButton(400, 200, -600, 900-((5-c)*200),"Bullet Speed +"+ (c+1), 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletSpeed(); } });
      upgradePanel.buttons.get(bulletSpeedButtons[c]).grayed = true;
      bulletWeightButtons[c] = upgradePanel.createButton(400, 200, 0, 900-((5-c)*200),"Bullet Power +"+ (c+1), 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeBulletSpeed(); } });
      upgradePanel.buttons.get(bulletWeightButtons[c]).grayed = true;
      fireRateButtons[c] = upgradePanel.createButton(400, 200, 600, 900-((5-c)*200),"Rate of Fire +"+ (c+1), 60, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { upgradeFireRate(); } });
      upgradePanel.buttons.get(fireRateButtons[c]).grayed = true;
    }
    
    guiPanel = new Panel(2500,100,0,-1200,false,50);
    guiPanel.createTextBox(20, 20, new StringPass() { String passed() { return ("Currency: " + money); } }, 50);
    
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

  void addtower(tower t) {
    towers.add(t);
  }

  void update() {
    if (state == State.RUNNING) {
      resources += resourceGain;
      currentMoneyTick++;
      if (currentMoneyTick == 40) {
        currentMoneyTick = 0;
        money += moneyGain;
        println("Currency: " + money);
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
  
  void upgradeBulletSpeed() {
    
  }
  
  void upgradeBulletWeight() {
    
  }
  
  void upgradeFireRate() {
    
  }
}
