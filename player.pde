// Copyright (C) 2015 evolveTD Copyright Holders

boolean follow_selected = true;
boolean show_siblings = false;
boolean show_cousins = false;

color on = color(100, 200, 50);
color off = color(200, 10, 10);

color clr_follow = on;
color clr_siblings = on;
color clr_cousins = on;

String cousins = "Not showing cousins";
String siblings = "Not showing siblings";
String following = "Not following a Creature";
String selected_creature = "No Creature Selected";

class player {
  ArrayList<structure> structures;
  ArrayList<Panel> upgradepanels;
  Panel playerPanel;
  Panel statsPanel;
  Panel hudPanel;
  Panel structurePanel;
  Panel helpPanel;
  Panel towerstatsPanel;
  Panel farmstatsPanel;
  Panel pricePanel;
  int rcost = 300;
  int pcost = 600;
  int icost = 1000;
  int lcost = 2000;
  int gcost = 4000;
  int bcost = 100;
  int dcost = 100;
  int money = 1000;
  int currentcost = 0;
  int moneytimer = 0;
  int activeweapon;     // value determines which weapon is active
  boolean placing = false;
  int numStructuresCreated = 0;
  int targetMode = 1;
  float framerate;
  int frameraterefreshtimer = 0;
  structure pickedup;
  
  Panel testpanel;
  creature selectedCreature;
  structure selectedStructure;
  Panel test;
  
  player() {
    framerate = 0;
    lasttime = millis();
    structures = new ArrayList<structure>();
    upgradepanels = new ArrayList<Panel>();
    activeweapon = 1;
    
    testpanel = new Panel(400,400,-1000,0,true);
    testpanel.createTextBox(400,200,0,-100,"THIS is a textbox!",40,true);
    testpanel.createButton(300,100,0,100,"Yay BUTTON",30,0,0,0,new ButtonPress() { public void pressed() { println("button has been pressed!!"); } });
    testpanel.enabled = false;

    playerPanel = new Panel(500,420,980,-1020,true);
    playerPanel.createTextBox(480,50,0,-20,new StringPass() { public String passed() { return ("Time left: " + (timepergeneration - timesteps)); } },40);
    playerPanel.createButton(350,100,0,110,"Wave Fire",50,new ButtonPress() { public void pressed() { wave_fire(); } });

    statsPanel = new Panel(500,520,980,1020-360,false); // -360 so it's not cut off the bottom of some people's screens
    statsPanel.setupTextBoxList(20,10,50,40);
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Creature: " + selectedCreature.num); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Health: " + selectedCreature.health + " / " + selectedCreature.maxHealth + " +" + selectedCreature.health_regen); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Fitness: " + selectedCreature.fitness); } });
    statsPanel.pushTextBox(new StringPass() { String passed() { return ("Max speed: " + (int)selectedCreature.maxMovementForce); } });
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
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'f' ? ("Farm type: " + selectedStructure.f.nametext) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'f' ? ("ID# " + selectedStructure.ID) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'f' ? ("Production Speed: X" + (selectedStructure.f.productionSpeedUpgrades+1)) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'f' ? ("Shield Strength: X" + (selectedStructure.f.shieldUpgrades+1)) : ""); } });
    farmstatsPanel.pushTextBox(new StringPass() { String passed() { return (selectedStructure.type == 'f' ? ("Shield Regeneration: X" + (selectedStructure.f.shieldRegenUpgrades+1)) : ""); } });
    farmstatsPanel.createButton(300,200,0,150,"Upgrade",50,new ButtonPress() { public void pressed() { if (selectedStructure.type == 'f') selectedStructure.f.upgradePanel.enabled = true; } });

    structurePanel = new Panel(2500, 300, 0, 1100-140, true); // -140 so it's not cut off the bottom of some people's screens
    structurePanel.createButton(250, 300, -1125, 0, rcost + "$\nRailgun", 45, 0, 0, 0, new ButtonPress() {public void pressed() { placeStructure('r'); } });
    structurePanel.createButton(250, 300, -875, 0, pcost + "$\nPlasma\nCannon", 45, 200, 0, 100, new ButtonPress() {public void pressed() { placeStructure('p'); } });
    structurePanel.createButton(250, 300, -625, 0, icost + "$\nFreeze\nTurret", 45, 0, 200, 255, new ButtonPress() {public void pressed() { placeStructure('i'); } });
    structurePanel.createButton(250, 300, -375, 0, lcost + "$\nLaser\nArtillery", 45, 220, 20, 20, new ButtonPress() {public void pressed() { placeStructure('l'); } });
    structurePanel.createButton(250, 300, -125, 0, gcost + "$\nElectron\nCloud\nGenerator", 45, 100, 255, 200, new ButtonPress() {public void pressed() { placeStructure('g'); } });
    structurePanel.createButton(250, 300, 375, 0, "Cost varies\nCable", 45, 100, 100, 100, new ButtonPress() {public void pressed() { placeStructure('c'); } });
    structurePanel.createButton(250, 300, 625, 0, bcost + "$\nDrill", 45, 50, 50, 50, new ButtonPress() {public void pressed() { placeStructure('d'); } });
    structurePanel.createButton(250, 300, 875, 0, bcost + "$\nBioreactor", 45, 50, 255, 50, new ButtonPress() {public void pressed() { placeStructure('b'); } });
    structurePanel.createButton(250, 300, 1125, 0, "X", 200, 255, 0, 0, new ButtonPress() {public void pressed() { deleteStructure(); } });
    structurePanel.buttons.get(structurePanel.buttons.size()-1).enabled = false;

    test =  new Panel(540,600,-960,980-1800,true);// -140 so it's not cut off the bottom of some people's screens

    
    test.createTextBox(500,100, 0,-150,new StringPass() { public String passed() { return (following); } },40);
    test.createTextBox(500,100, 0,0,new StringPass() { public String passed() { return (siblings); } },40);
    test.createTextBox(500,100, 0,150,new StringPass() { public String passed() { return (cousins); } },40);
    
    test.createButton(500, 100, 0, -150, "", 45, (int)red(clr_follow), (int)green(clr_follow), (int)blue(clr_follow), new ButtonPress() {public void pressed() { follow_selected = !follow_selected; } });
    test.createButton(500, 100, 0, 0, "", 45, (int)red(clr_siblings), (int)green(clr_siblings), (int)blue(clr_siblings), new ButtonPress() {public void pressed() { show_siblings = !show_siblings; } });
    test.createButton(500, 100, 0, 150, "", 45, (int)red(clr_cousins), (int)green(clr_cousins), (int)blue(clr_cousins), new ButtonPress() {public void pressed() { show_cousins = !show_cousins; } });
    
    
    //test.buttons.get(structurePanel.buttons.size()-1).enabled = false;


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
                         +"by moving it to the X button on the right side\nof the structure management panel and clicking it.");

    hudPanel = new Panel(2500,100,0,-1200,false,100);
    hudPanel.createTextBox(20, 20, new StringPass() { String passed() { return ("Currency: " + (mistermoneybagsmode ? "One billion dollars!" : money) + "\t\t\t\tWave: " + (generation+1) + "\t\t\t\tAutofire: " + (autofire ? "ON" : "OFF") + "\t\t\t\tFramerate: " + framerate); } }, 50);

    pricePanel = new Panel(100,40,0,0,false,0);
    pricePanel.createTextBox(0, 0, new StringPass() { String passed() { return ("$" + currentcost); } }, 50, true);
    pricePanel.enabled = false;

    selectedCreature = null;
  }

  void display() {
    if (selectedCreature != null) {
      

      // only follow if alive
      if (selectedCreature.alive) {

          if (follow_selected) {
            clr_follow = on;
            following = "Following a Creature";
          } else {
            clr_follow = off;
            following = "Not following a Creature";
          }
          
          
          if (show_siblings) {
            clr_siblings = on;
            siblings = "Showing siblings";

          } else {
            clr_siblings = off;
             siblings = "Not showing siblings";  
          }
          
          if (show_cousins) {
            clr_cousins = on;
            cousins = "Showing cousins";
          } else {
            clr_cousins = off;
            cousins = "Not showing cousins";
          }

        Vec2 pos = box2d.getBodyPixelCoord(selectedCreature.body);
        if (follow_selected) {
          cameraX = int(pos.x);
          cameraY = int(pos.y);
        }
        
        pushMatrix();
        for (creature c : the_pop.swarm) {
          if (c.alive) {
            Vec2 pos_tmp = box2d.getBodyPixelCoord(c.body);
            if(show_siblings) {
              if (selectedCreature.parents[0] != -1 && (c.parents[0] == selectedCreature.parents[0] || c.parents[0] == selectedCreature.parents[1])) { 
                fill( 253, 246, 250);
                arc(pos_tmp.x, pos_tmp.y, 100, 100,  HALF_PI, 3*HALF_PI);
              }
              
              if (selectedCreature.parents[0] != -1 && (c.parents[1] == selectedCreature.parents[0] || c.parents[1] == selectedCreature.parents[1])) { 
                fill(25, 45, 200);
                arc(pos_tmp.x, pos_tmp.y, 100, 100,  -HALF_PI, HALF_PI);
              }
            }
            if (show_cousins) {
              for (int selected_i = 0; selected_i < 4; selected_i++) {
                for (int test_i = 0; test_i < 4; test_i++) {
                   if (selectedCreature.grandparents[selected_i] != -1 && c.grandparents[test_i] == selectedCreature.grandparents[selected_i]) {
                      if (test_i == 0) {
                        fill(100, 0, 100);
                        triangle(pos_tmp.x, pos_tmp.y, pos_tmp.x+50, pos_tmp.y, pos_tmp.x, pos_tmp.y+50);
                      } else if (test_i == 1) {
                        fill(100, 100, 100);
                        triangle(pos_tmp.x, pos_tmp.y, pos_tmp.x-50, pos_tmp.y, pos_tmp.x, pos_tmp.y+50);
                      } else if (test_i == 2) {
                        fill(150, 20, 20);
                        triangle(pos_tmp.x, pos_tmp.y, pos_tmp.x+50, pos_tmp.y, pos_tmp.x, pos_tmp.y-50);
                      } else if (test_i == 3) {
                        fill(200, 200, 100);
                        triangle(pos_tmp.x, pos_tmp.y, pos_tmp.x-50, pos_tmp.y, pos_tmp.x, pos_tmp.y-50);
                      }
                      
                      
                   }
                }
              }  
              }
          }
        }
        popMatrix();
      }
      selected_creature = "Creature Selected";
      statsPanel.enabled = true;
    } else {
      selected_creature = "No Creature Selected";
      follow_selected = true;
      statsPanel.enabled = false;
    }
    
    if (selectedStructure != null) {
      if (selectedStructure.type == 'f') {
        towerstatsPanel.enabled = false;
        farmstatsPanel.enabled = true;
      }
      else if (selectedStructure.type == 't') {
        farmstatsPanel.enabled = false;
        towerstatsPanel.enabled = true;
      }
    }
    else {
      towerstatsPanel.enabled = false;
      farmstatsPanel.enabled = false;
    }

    rectMode(CENTER);
    if (placing) {
      for (structure s : structures) if (s.type == 'c' && s.ID != pickedup.ID) s.c.display(); // cables get drawn first so they're not covering up structures
      for (structure s : structures) { // walk through the structures
        if (s.type == 'f' && s.ID != pickedup.ID) s.f.display();  // display them all
        else if (s.type == 't' && s.ID != pickedup.ID) s.t.display();
      }
      if (pickedup.type == 't') pickedup.t.display();
      else if (pickedup.type == 'f') pickedup.f.display();
      else if (pickedup.type == 'c') {
        pickedup.c.display();
        if (pickedup.c.otherEnd != null) pickedup.c.otherEnd.display();
      }
    }
    else {
      for (structure s : structures) if (s.type == 'c') s.c.display(); // cables get drawn first so they're not covering up structures
      for (structure s : structures) { // walk through the structures
        if (s.type == 'f') s.f.display();  // display them all
        else if (s.type == 't') s.t.display();
      }
    }
    for (Panel p : panels)
      p.display();
  }

  void update() {
    if (pickedup != null ? pickedup.type == 'c' : false) {
      pricePanel.panel_x = worldRatioX*(mouseX-(width/2))+2*pickedup.c.radius+((zoomOffset-cameraZ)/10);
      pricePanel.panel_y = worldRatioY*(mouseY-(height/2))+pickedup.c.radius+((zoomOffset-cameraZ)/10);
    }
    frameraterefreshtimer++;
    if (frameraterefreshtimer == 20) {
      framerate = (20000.0 / (millis() - lasttime));
      lasttime = millis();
      frameraterefreshtimer = 0;
    }
    // walk through the structures
    for (int i = structures.size() - 1; i >= 0; i--) {
      if (structures.get(i).type == 'f') {
        structures.get(i).f.update(); // update them
        if (structures.get(i).f.remove) { // delete if it's dead
          structures.get(i).f.farm_body.setUserData(null);
          for (Fixture f = structures.get(i).f.farm_body.getFixtureList(); f != null; f = f.getNext())
            f.setUserData(null);
          box2d.destroyBody(structures.get(i).f.farm_body); // destroy the body of a dead farm
          structures.remove(i);
        }
      }
      else if (structures.get(i).type == 't') {
        structures.get(i).t.update(); // update them
        if (structures.get(i).t.remove) { // delete if it's dead
          structures.get(i).t.tower_body.setUserData(null);
          for (Fixture f = structures.get(i).t.tower_body.getFixtureList(); f != null; f = f.getNext())
            f.setUserData(null);
          box2d.destroyBody(structures.get(i).t.tower_body); // destroy the body of a dead tower
          structures.remove(i);
        }
      }
      else if (structures.get(i).type == 'c') {
        structures.get(i).c.update(); // update them
        if (structures.get(i).c.remove) {
          if (pickedup.c.otherEnd != null) {
            pickedup.c.otherEnd.terminal_body.setUserData(null);
            for (Fixture f = pickedup.c.otherEnd.terminal_body.getFixtureList(); f != null; f = f.getNext())
              f.setUserData(null);
            box2d.destroyBody(pickedup.c.otherEnd.terminal_body); // destroy the body of a dead terminal
            structures.remove(pickedup.c.otherEnd.parent);
          }
          pickedup.c.terminal_body.setUserData(null);
          for (Fixture f = pickedup.c.terminal_body.getFixtureList(); f != null; f = f.getNext())
            f.setUserData(null);
          box2d.destroyBody(pickedup.c.terminal_body); // destroy the body of a dead terminal
          structures.remove(i);
        }
      }
    }
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).update();
    if (state == State.RUNNING) {
      if (moneytimer == 10) {
        moneytimer = 0;
        money += (generation);
      }
      moneytimer++;
    }
  }

  void mouse_pressed() {
    // check if the mouse was pressed in the player panel
    int s = panels.size();
    for (int i = 0; i < s; i++)
      if (panels.get(i).mouse_pressed())break;
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
  
  void updateStructures() {
    for (structure z : structures)
      if (placing?(z.ID != pickedup.ID):true) // ensure that this structure isn't currently picked up
        switch (z.type) {
          case 'f':
            if (z.f.type == 'b') {
              z.f.connectedCables.clear();
              for (structure s : structures)
                if (placing?(s.ID != pickedup.ID):true) // ensure that this structure isn't currently picked up
                  if (s.type == 'c')
                    if (s.c.xpos == z.f.xpos && s.c.ypos == z.f.ypos && s.c.enabled)
                      z.f.connectedCables.add(s.c);
            }
            break;
          case 'c':
            z.c.connectedStructures.clear();
            if (z.c.enabled) {
              for (structure s : structures)
                if (placing?(s.ID != pickedup.ID):true) // ensure that this structure isn't currently picked up
                  switch (s.type) {
                    case 't':
                      if (s.t.xpos == z.c.xpos && s.t.ypos == z.c.ypos)
                        z.c.connectedStructures.add(s);
                      break;
                    case 'f':
                      if (s.f.type == 'd')
                        if (s.f.xpos == z.c.xpos && s.f.ypos == z.c.ypos)
                          z.c.connectedStructures.add(s);
                      break;
                    case 'c':
                      if (s.c.xpos == z.c.xpos && s.c.ypos == z.c.ypos && s.c.enabled)
                        z.c.connectedStructures.add(s);
                      break;
                  }
            }
            break;
        }
  }
  
  void placeStructure(char type) {
    if (placing) {
      if (type == (pickedup.type == 'f' ? pickedup.f.type : (pickedup.type == 't' ? pickedup.t.type : pickedup.c.type)))
        deleteStructure(); // if the button pressed is the same as the structure held, sell the held structure
      else switchStructure(type); // else sell the held structure and pick up a new one
    }
    else { // else try to buy a new structure
      int cost = 0;
      switch (type) {
        case 'r':
          cost = rcost;
          break;
        case 'p':
          cost = pcost;
          break;
        case 'i':
          cost = icost;
          break;
        case 'l':
          cost = lcost;
          break;
        case 'g':
          cost = gcost;
          break;
        case 'b':
          cost = bcost;
          break;
        case 'd':
          cost = dcost;
          break;
        case 'c':
          cost = 0;
          break;
      }
      if (money < cost) {
        println("You do not have sufficient funds to purchase this structure...");
        return;
      }
      money -= cost;
      placing = true;
      pickedup = new structure(type, ++numStructuresCreated);
      if (type == 'c') {
        currentcost = cost;
        pricePanel.enabled = true;
      }
      structures.add(pickedup);
      structurePanel.buttons.get(structurePanel.buttons.size()-1).enabled = true;
      structurePanel.hiddenpanel = false;
    }
  }
  
  void switchStructure(char type) {
    structures.remove(pickedup);
    money += (pickedup.moneyinvested/2);
    selectedStructure = null;
    int cost = 0;
    switch (type) {
      case 'r':
        cost = rcost;
        break;
      case 'p':
        cost = pcost;
        break;
      case 'i':
        cost = icost;
        break;
      case 'l':
        cost = lcost;
        break;
      case 'g':
        cost = gcost;
        break;
      case 'b':
        cost = bcost;
        break;
      case 'd':
        cost = dcost;
        break;
      case 'c':
        cost = 0;
        break;
    }
    if (money < cost) {
      println("You do not have sufficient funds to purchase this structure...");
      placing = false;
      if (pickedup.type == 'c') pricePanel.enabled = false;
      pickedup = null;
      pricePanel.enabled = false;
      structurePanel.buttons.get(structurePanel.buttons.size()-1).enabled = false;
      structurePanel.hiddenpanel = true;
      return;
    }
    money -= cost;
    pickedup = new structure(type, ++numStructuresCreated);
    if (type == 'c') {
      currentcost = cost;
      pricePanel.enabled = true;
    }
    structures.add(pickedup);
  }
  
  void deleteStructure() {
    placing = false;
    structures.remove(pickedup);
    if (pickedup.type == 'c') {
      money += (pickedup.c.previouscost/2);
      pricePanel.enabled = false;
      if (pickedup.c.otherEnd != null) {
        pickedup.c.otherEnd.destroybody();
        structures.remove(pickedup.c.otherEnd.parent);
      }
    }
    else money += (pickedup.moneyinvested/2);
    pickedup = null;
    structurePanel.buttons.get(structurePanel.buttons.size()-1).enabled = false;
    structurePanel.hiddenpanel = true;
    selectedStructure = null;
  }
}
