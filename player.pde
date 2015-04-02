class player {
  ArrayList<tower> towers;
  PlayerPanel panel;
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep

  player(){
    towers = new ArrayList<tower>();
    panel = new PlayerPanel();
    resources = 0;
    resourceGain = 0.1;
  }

  void display(){
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.display();  // display them all
    }
    panel.display();
  }

  void addtower(tower t){
    towers.add(t);
  }

  void update(){
    resources += resourceGain;
    for (int i = towers.size() - 1; i >= 0; i--){  // walk through the towers
      tower t = towers.get(i);
      t.update();   // update them
    }
    panel.update();
  }

  void mouse_pressed(){
    panel.mouse_pressed();  // check if the mouse was pressed in the upperright GUI panel
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

    void display(){
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
}
