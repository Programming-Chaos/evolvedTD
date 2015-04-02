class player {
  ArrayList<tower> towers;
  PlayerPanel playerPanel;
  StatsPanel statsPanel;
  
  Panel testpanel;
  
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  creature selectedCreature;

  player() {
    testpanel = new Panel(400,400,-1000,0,true);
    testpanel.createTextBox(400,200,0,-100,"THIS is a textbox!",40);
    testpanel.createButton(300,100,0,100,"Yay BUTTON",30,new ButtonPress() { public void pressed() { println("button has been pressed!!"); } });
    testpanel.enabled = false;
    panels.add(testpanel);
    towers = new ArrayList<tower>();
    playerPanel = new PlayerPanel();
    statsPanel = new StatsPanel();
    resources = 0;
    resourceGain = 0.1;
    selectedCreature = null;
  }

  void display() {
    for (int i = towers.size() - 1; i >= 0; i--)  // walk through the towers
      towers.get(i).display();  // display them all
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).display();

    playerPanel.display();
    if (selectedCreature != null) {
      Vec2 pos = box2d.getBodyPixelCoord(selectedCreature.body);
      cameraX = int(pos.x);
      cameraY = int(pos.y);
      statsPanel.display();
    }
  }

  void addtower(tower t) {
    towers.add(t);
  }

  void update() {
    resources += resourceGain;
    // walk through the towers
    for (int i = towers.size() - 1; i >= 0; i--)
      towers.get(i).update();   // update them
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).update();
    playerPanel.update();
  }

  void mouse_pressed() {
    // check if the mouse was pressed in the player panel
    for (int i = panels.size() - 1; i >= 0; i--)
      panels.get(i).mouse_pressed();
    playerPanel.mouse_pressed();
  }

  void wave_fire(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.wave_fire();
    }
  }

  class PlayerPanel {
    float w = 350;
    float h = 200;
    float x = w;
    boolean displayed = false;

    void display() {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
      translate(cameraX + (worldWidth - x)/2, cameraY + (h - worldHeight)/2, cameraZ - zoomOffset);

      fill(255, 255, 255, 150);
      rect(0, 0, w, h);
      fill(0, 0, 0, 200);

      float leftalign = -w/2 + 4;
      float topalign = -h/2;
      int fontSize = 40;
      textSize(fontSize);

      text("Resources: " + int(the_player.resources), leftalign, topalign + 1 * fontSize);
      text("Generation: " + generation, leftalign, topalign + 2 * fontSize);
      text("Time left: " + (timepergeneration - timesteps), leftalign, topalign + 3 * fontSize);

      fill(255,0,0,200);

      // wave fire button
      rect(0, topalign + 4 * fontSize + 10, w - 40, fontSize + 10);
      fill(0, 0, 0, 200);
      text("Wave Fire", -w/4, topalign + 4 * fontSize + 20);

      hint(ENABLE_DEPTH_TEST);
      popMatrix();
    }

    void update() {
      // if the upper right third
      if (mouseX > 2 * width / 3 && mouseY < height / 3) {
        // shift if not fully displayed
        if (x < w) {
          x += w * 0.1;
        } else {
          displayed = true;
        }
      } else if (x > -w){
        x -= w * 0.1;
        displayed = false;
      }
    }

    void mouse_pressed() {
      if (!displayed) { // only handle mouse presses in an extended panel
        return;
      }
      if (mouseX > 5 * width / 6 && mouseY < height / 6) {
        the_player.wave_fire();
      }
    }
  }

  class StatsPanel {
    float w = 500;
    float h = 420;

    void display() {
      if (selectedCreature == null)
        return;
      creature c = selectedCreature;

      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
      translate(cameraX + (worldWidth - w)/2, cameraY + worldHeight/2 - h, cameraZ - zoomOffset);

      fill(255, 255, 255, 150);
      rect(0, 0, w, h);
      fill(0, 0, 0, 200);

      float leftalign = -w/2 + 4;
      float topalign = -h/2;
      int fontSize = 40;
      textSize(fontSize);

      text("Creature: " + c.num, leftalign, topalign + 1 * fontSize);
      text("Health: " + c.health + " / " + c.maxHealth + " +" + c.health_regen, leftalign, topalign + 2 * fontSize);
      text("Fitness: " + c.fitness, leftalign, topalign + 3 * fontSize);
      text("Max speed: " + int(c.maxMovementSpeed), leftalign, topalign + 4 * fontSize);
      text("Time in water: " + c.time_in_water, leftalign, topalign + 5 * fontSize);
      text("Time on land: " + c.time_on_land, leftalign, topalign + 6 * fontSize);
      text("Scent strength: " + c.scentStrength, leftalign, topalign + 7 * fontSize);
      text("Reproduction energy: " + int(c.energy_reproduction), leftalign, topalign + 8 * fontSize);
      text("Locomotion energy: " + int(c.energy_locomotion), leftalign, topalign + 9 * fontSize);
      text("Health energy: " + int(c.energy_health), leftalign, topalign + 10 * fontSize);

      fill(255,0,0,200);
      hint(ENABLE_DEPTH_TEST);
      popMatrix();
    }
  }
}
