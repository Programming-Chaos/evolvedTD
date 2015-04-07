class player {
  ArrayList<tower> towers;
  ArrayList<Panel> upgradepanels;
  Panel playerPanel;
  Panel statsPanel;
  Panel hudPanel;
  Panel towerPanel;
  Panel helpPanel;
  Panel towerstatsPanel;
  int money = 0;
  int moneyGain = 10; // money per 40 ticks
  int currentMoneyTick;
  int activeweapon;     // value determines which weapon is active
  boolean placing = false;
  int numTowersCreated = 0;
  tower pickedup;
  
  Panel testpanel;
  
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  creature selectedCreature;
  tower selectedTower;

  player() {
    towers = new ArrayList<tower>();
    upgradepanels = new ArrayList<Panel>();
    activeweapon = 1;
    
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

    towerstatsPanel = new Panel(540,600,-980,1020-200,false);//-200 so it's not cut off the bottom of some people's screens
    towerstatsPanel.enabled = false;
    towerstatsPanel.setupTextBoxList(40,50,50,40);
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return ("Turret type: " + ((selectedTower.type == 'r') ? "Railgun" : "Flamethrower")); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return ("ID# " + selectedTower.ID); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return ("Bullet speed: X" + (selectedTower.bulletSpeedUpgrades+1)); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return ("Bullet damage: X" + (selectedTower.bulletDamageUpgrades+1)); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return ("Rate of fire: X" + (selectedTower.fireRateUpgrades+1)); } });
    towerstatsPanel.createButton(300,200,0,150,"Upgrade",50,new ButtonPress() { public void pressed() { selectedTower.upgradePanel.enabled = true; } });

    towerPanel = new Panel(2500, 300, 0, 1100, true);
    towerPanel.createButton(300, 300, -1100, 0, "Railgun", 45, 0, 0, 0, new ButtonPress() {public void pressed() { placeTurret('r'); } });
    towerPanel.createButton(300, 300, -800, 0, "Flamethrower", 45, 200, 0, 0, new ButtonPress() {public void pressed() { placeTurret('f'); } });
    towerPanel.createButton(300, 300, 1100, 0, "X", 200, 255, 0, 0, new ButtonPress() {public void pressed() { deleteTurret(); } });
    towerPanel.buttons.get(2).enabled = false;

    helpPanel = new Panel(600,600,0,0,false);
    helpPanel.enabled = false;
    helpPanel.createTextBox(30,30,"Controls",60);
    helpPanel.setupTextBoxList(30,90,40,40);
    helpPanel.pushTextBox("w/s - zoom in/out");
    helpPanel.pushTextBox("Arrow keys - move camera");
    helpPanel.pushTextBox("z - zoom out");
    helpPanel.pushTextBox("p - pause/unpause");
    helpPanel.pushTextBox("u - show upgrades");
    helpPanel.pushTextBox("Mouse button - fire");
    helpPanel.pushTextBox("Number keys - switch weapons");
    helpPanel.pushTextBox("q - hide/unhide food");
    helpPanel.pushTextBox("n - hide/unhide scent");
    helpPanel.pushTextBox("v - hide/unhide screen");
    helpPanel.pushTextBox("? - show/hide controls");
    helpPanel.pushTextBox("a - toggle autofire");

    hudPanel = new Panel(2500,100,0,-1200,false,0);
    hudPanel.createTextBox(20, 20, new StringPass() { String passed() { return ("Currency: " + money); } }, 50);

    resources = 0;
    resourceGain = 0.1;
    selectedCreature = null;
  }

  void display() {
    if (selectedCreature != null) {
      // only follow if alive
      if (selectedCreature.alive) {
        Vec2 pos = box2d.getBodyPixelCoord(selectedCreature.body);
        cameraX = int(pos.x);
        cameraY = int(pos.y);
      }
      statsPanel.enabled = true;
    } else {
      statsPanel.enabled = false;
    }

    for (tower t : towers)  // walk through the towers
      t.display();  // display them all
    for (Panel p : panels)
      p.display();
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
    int s = panels.size();
    for (int i = 0; i < s; i++)
      panels.get(i).mouse_pressed();
  }

  void wave_fire(){
    if (state == State.RUNNING) {
      for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
        tower t = towers.get(i);
        t.wave_fire();
      }
    }
  }

  void next_generation(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.next_generation();
    }
    moneyGain *= 2;
  }

  void drop_rock() {
    float x,y;
    int costPerTurret = round((float)100/towers.size()); // spread out energy cost equally among turrets
    
    // Try to figure out, given the pixel coordinates of the mouse and the camera position, where in the virtual world the cursor is
    //x = cameraX + (cameraZ*sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    //y = cameraY + (cameraZ*sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    for (tower t : towers)
      if (t.energy < costPerTurret)return;
    for (tower t : towers)
      t.energy -= costPerTurret;  // uses a lot of energy to drop a rock
    rocks.add(new rock(round(mouse_x), round(mouse_y))); // rocks is a global list
  }
  
  void placeTurret(char type) {
    if (placing) {
      placing = false;
      switch (pickedup.type) {
        case 'r':
          towers.remove(pickedup);
          pickedup = null;
          towerPanel.buttons.get(2).enabled = false;
          towerPanel.hiddenpanel = true;
          towerPanel.shown = false;
          if (type == 'f') placeTurret('f');
          break;
        case 'f':
          towers.remove(pickedup);
          pickedup = null;
          towerPanel.buttons.get(2).enabled = false;
          towerPanel.hiddenpanel = true;
          towerPanel.shown = false;
          if (type == 'r') placeTurret('r');
          break;
      }
    }
    else {
      placing = true;
      pickedup = new tower(type, ++numTowersCreated);
      towers.add(pickedup);
      towerPanel.buttons.get(2).enabled = true;
      towerPanel.hiddenpanel = false;
      towerPanel.shown = true;
    }
  }
  
  void deleteTurret() {
    towers.remove(pickedup);
    pickedup = null;
    towerPanel.buttons.get(2).enabled = false;
    placing = false;
    towerPanel.hiddenpanel = true;
    towerPanel.shown = false;
  }
}
