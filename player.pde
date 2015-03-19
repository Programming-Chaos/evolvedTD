class player {
  ArrayList<tower> towers;
  panel upper_right;
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep

  player() {
    towers = new ArrayList<tower>();
    upper_right = new panel(100, 100);
    resources = 0;
    resourceGain = 0.1;
  }

  void display() {
    for (int i = towers.size() - 1; i >= 0; i--) { // walk through the towers
      tower t = towers.get(i);
      t.display();  // display them all
    }

    // player UI here
    upper_right.display();
  }

  void addtower(tower t) {
    towers.add(t);
  }

  void update() {
    resources += resourceGain;

    for (int i = towers.size() - 1; i >= 0; i--) { // walk through the towers
      tower t = towers.get(i);
      t.update();   // update them
    }

    upper_right.update();  // update GUI panel
  }

  void mouse_pressed() {
    upper_right.mouse_pressed();  // check if the mouse was pressed in the upperright GUI panel
  }

  void wave_fire() {
    for (int i = towers.size() - 1; i >= 0; i--) { // walk through the towers
      tower t = towers.get(i);
      t.wave_fire();
    }
  }


}
