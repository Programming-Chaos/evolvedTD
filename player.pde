class player {
  ArrayList<structure> structures;
  ArrayList<Panel> upgradepanels;
  Panel playerPanel;
  Panel statsPanel;
  Panel hudPanel;
  Panel towerPanel;
  Panel helpPanel;
  Panel towerstatsPanel;
  Panel farmstatsPanel;
  int money = 0;
  int moneytimer = 0;
  int activeweapon;     // value determines which weapon is active
  boolean placing = false;
  int numStructuresCreated = 0;
  int targetMode = 1;
  structure pickedup;
  
  Panel testpanel;
  
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  creature selectedCreature;
  structure selectedStructure;

  player() {
    structures = new ArrayList<structure>();
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

    statsPanel = new Panel(500,520,980,1020-360,false); // -360 so it's not cut off the bottom of some people's screens
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

    towerstatsPanel = new Panel(540,700,-960,930-360,false); // -360 so it's not cut off the bottom of some people's screens
    towerstatsPanel.enabled = false;
    towerstatsPanel.setupTextBoxList(40,50,50,40);
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Turret type: " + selectedStructure.t.nametext) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("ID# " + selectedStructure.ID) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Bullet speed: X" + (selectedStructure.t.bulletSpeedUpgrades+1)) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Bullet damage: X" + (selectedStructure.t.bulletDamageUpgrades+1)) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Rate of fire: X" + (selectedStructure.t.fireRateUpgrades+1)) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Shield Strength: X" + (selectedStructure.t.shieldUpgrades+1)) : ""); } });
    towerstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 't' ? ("Shield Regeneration: X" + (selectedStructure.t.shieldRegenUpgrades+1)) : ""); } });
    towerstatsPanel.createButton(300,200,0,200,"Upgrade",50,new ButtonPress() { public void pressed() { selectedStructure.t.upgradePanel.enabled = true; } });

    farmstatsPanel = new Panel(540,600,-960,980-360,false); // -360 so it's not cut off the bottom of some people's screens
    farmstatsPanel.enabled = false;
    farmstatsPanel.setupTextBoxList(40,50,50,40);
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'b' ? ("Farm type: " + selectedStructure.f.nametext) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'b' ? ("ID# " + selectedStructure.ID) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'b' ? ("Production Speed: X" + (selectedStructure.f.productionSpeedUpgrades+1)) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'b' ? ("Shield Strength: X" + (selectedStructure.f.shieldUpgrades+1)) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'b' ? ("Shield Regeneration: X" + (selectedStructure.f.shieldRegenUpgrades+1)) : ""); } });
    farmstatsPanel.createButton(300,200,0,150,"Upgrade",50,new ButtonPress() { public void pressed() { if (selectedStructure.type == 'b') selectedStructure.f.upgradePanel.enabled = true; } });

    towerPanel = new Panel(2500, 300, 0, 1100, true);
    towerPanel.createButton(300, 300, -1100, 0, "Railgun", 45, 0, 0, 0, new ButtonPress() {public void pressed() { placeStructure('r'); } });
    towerPanel.createButton(300, 300, -800, 0, "Plasma\nCannon", 45, 200, 0, 100, new ButtonPress() {public void pressed() { placeStructure('p'); } });
    towerPanel.createButton(300, 300, -500, 0, "Freeze\nTurret", 45, 0, 200, 255, new ButtonPress() {public void pressed() { placeStructure('i'); } });
    towerPanel.createButton(300, 300, -200, 0, "Laser\nArtillery", 45, 220, 20, 20, new ButtonPress() {public void pressed() { placeStructure('l'); } });
    towerPanel.createButton(300, 300, 100, 0, "Electron\nCloud\nGenerator", 45, 100, 255, 200, new ButtonPress() {public void pressed() { placeStructure('g'); } });
    towerPanel.createButton(300, 300, 800, 0, "Bioreactor", 45, 50, 255, 50, new ButtonPress() {public void pressed() { placeStructure('b'); } });
    towerPanel.createButton(300, 300, 1100, 0, "X", 200, 255, 0, 0, new ButtonPress() {public void pressed() { deleteStructure(); } });
    towerPanel.buttons.get(towerPanel.buttons.size()-1).enabled = false;

    helpPanel = new Panel(1000,1900,0,0,false,255);
    helpPanel.enabled = false;
    helpPanel.createTextBox(30,20,"Controls",60);
    helpPanel.setupTextBoxList(30,90,40,40);
    helpPanel.pushTextBox("w/s - zoom in/out");
    helpPanel.pushTextBox("Arrow keys - move camera");
    helpPanel.pushTextBox("z - zoom all the way out");
    helpPanel.pushTextBox("c - center the camera");
    helpPanel.pushTextBox("a - toggle autofire");
    helpPanel.pushTextBox("p - pause/unpause");
    helpPanel.pushTextBox("u - shows upgrades");
    helpPanel.pushTextBox("     when hovering over tower");
    helpPanel.pushTextBox("1 - switch to firing mode");
    helpPanel.pushTextBox("2 - switch to rock placing mode");
    helpPanel.pushTextBox("q - hide/unhide food");
    helpPanel.pushTextBox("n - hide/unhide scent");
    helpPanel.pushTextBox("e - hide/unhide feelers");
    helpPanel.pushTextBox("v - hide/unhide screen");
    helpPanel.pushTextBox("? - show/hide controls");
    helpPanel.pushTextBox("\nClick the Left Mouse button\nto fire or place a rock.\n"
                         +"Click the Right Mouse button\nto select creature or tower.\n"
                         +"You can also create new towers by\nhovering near the lower edge of the screen\n"
                         +"to bring up the tower management panel,\n"
                         +"and clicking on one of the tower creation buttons.\n"
                         +"you can then move the new tower\nwhere you'd like it to go,\n"
                         +"and click the left mouse button to place it down.\n"
                         +"If you've selected an existing tower\nand you right click it again,\n"
                         +"you'll pick it up and can move it around\nand place it back down.\n"
                         +"If you're holding a tower you can delete it\n"
                         +"by moving it to the X button on the right side\nof the tower management panel and clicking it.");

    hudPanel = new Panel(1250,100,-625,-1200,false,100);
    hudPanel.createTextBox(20, 20, new StringPass() { String passed() { return ("Currency: " + money + "\t\t\t\t\t\tWave: " + (generation+1) + "\t\t\t\t\t\tAutofire: " + (autofire ? "ON" : "OFF")); } }, 50);

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
    
    if (selectedStructure != null) {
      if (selectedStructure.type == 'b') {
        towerstatsPanel.enabled = false;
        farmstatsPanel.enabled = true;
      }
      else {
        farmstatsPanel.enabled = false;
        towerstatsPanel.enabled = true;
      }
    }
    else {
      towerstatsPanel.enabled = false;
      farmstatsPanel.enabled = false;
    }

    rectMode(CENTER);
    for (structure s : structures) { // walk through the structures
      if (s.type == 'b') s.f.display();  // display them all
      else s.t.display();
      
    }
    for (Panel p : panels)
      p.display();
  }

  void update() {
    if (state == State.RUNNING) {
      resources += resourceGain;
    }
    // walk through the structures
    for (int i = structures.size() - 1; i >= 0; i--) {
      if (structures.get(i).type == 'b') {
        structures.get(i).f.update(); // update them
        if (structures.get(i).f.remove) { // delete if it's dead
          structures.get(i).f.farm_body.setUserData(null);
          for (Fixture f = structures.get(i).f.farm_body.getFixtureList(); f != null; f = f.getNext())
            f.setUserData(null);
          box2d.destroyBody(structures.get(i).f.farm_body); // destroy the body of a dead farm
          structures.remove(i);
        }
      }
      else {
        structures.get(i).t.update(); // update them
        if (structures.get(i).t.remove) { // delete if it's dead
          structures.get(i).t.tower_body.setUserData(null);
          for (Fixture f = structures.get(i).t.tower_body.getFixtureList(); f != null; f = f.getNext())
            f.setUserData(null);
          box2d.destroyBody(structures.get(i).t.tower_body); // destroy the body of a dead tower
          structures.remove(i);
        }
      }
    }
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).update();
    if (state == State.RUNNING) {
      if (moneytimer == 10) {
        moneytimer = 0;
        money += (generation+1);
      }
      moneytimer++;
    }
  }

  void mouse_pressed() {
    // check if the mouse was pressed in the player panel
    int s = panels.size();
    for (int i = 0; i < s; i++)
      panels.get(i).mouse_pressed();
  }

  void wave_fire(){
    if (state == State.RUNNING)
      for (int i = structures.size() - 1; i >= 0; i--) // walk through the towers
        if (structures.get(i).type == 't') structures.get(i).t.wave_fire();
  }

  void next_generation(){
    for (int i = structures.size() - 1; i >= 0; i--) // walk through the towers
      if (structures.get(i).type == 't') structures.get(i).t.next_generation();
  }

  void drop_rock() {
    if (money < 50) {
      println("You do not have enough money to place a rock (costs 50)");
      return;
    }
    money -= 50;
    rocks.add(new rock(round(mouse_x), round(mouse_y))); // rocks is a global list
  }
  
  void placeStructure(char type) {
    if (placing) {
      if (type != pickedup.type) switchStructure(type);
      else deleteStructure();
    }
    else {
      placing = true;
      pickedup = new structure(type, ++numStructuresCreated);
      structures.add(pickedup);
      towerPanel.buttons.get(towerPanel.buttons.size()-1).enabled = true;
      towerPanel.hiddenpanel = false;
    }
  }
  
  void switchStructure(char type) {
    structures.remove(pickedup);
    selectedStructure = null;
    pickedup = new structure(type, ++numStructuresCreated);
    structures.add(pickedup);
  }
  
  void deleteStructure() {
    placing = false;
    structures.remove(pickedup);
    pickedup = null;
    towerPanel.buttons.get(towerPanel.buttons.size()-1).enabled = false;
    towerPanel.hiddenpanel = true;
    selectedStructure = null;
  }
}
