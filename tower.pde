class tower {
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int maxEnergy = 1000; // max energy the tower can have
  int activeweapon;     // value determines which weapon is active
  ArrayList<projectile> projectiles;
  float angle;
  boolean autofire = true;
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  
  tower() {
    energy = maxEnergy;
    activeweapon = 1;
    projectiles = new ArrayList<projectile>();
    angle = 0;
  }
  
  void update() {
    if (autofire) {
      Vec2 target;
      
      autofirecounter++;
      if (autofirecounter % 20 == 0 & !paused) { // only autofire every Nth time step
        //target = the_pop.closest(new Vec2(0,0)); // target the closest creature
        target = the_pop.vec_to_random_creature(); // target a random creature
        angle = atan2(target.y,target.x);
        fire();
        autofirecounter = 0;
      }
    }
    else {
      // calculate the location of the mouse pointer in the world
      float x, y;
      float dx, dy;
      dx = mouseX + cameraX;
      dy = mouseY + cameraY;
      x = cameraX + (cameraZ/(0.5*sqrt(width*width+height*height)))*(mouseX-width*0.5);
      y = cameraY + (cameraZ/(0.5*sqrt(width*width+height*height)))*(mouseY-height*0.5);
      //calculate the angle to the mouse pointer
      angle = atan2(y, x);
    }
  }
  
  void display() {
    // draw a line 
    stroke(255, 0, 0);
    line(0, 0, 30*cos(angle), 30*sin(angle));
    //draw the tower
    ellipse(0, 0, 10, 10); // just a circle for now
    
    for (projectile p: projectiles) { // display the active projectiles
      p.display();
    } 
  
    // draw tower energy bar
    noFill();
    stroke(0);
    rectMode(CENTER);
    rect(0, -30, 0.1*maxEnergy, 6);
    noStroke();
    fill(0, 0, 255);
    rect(0, -30, 0.1*energy, 6);  
  }
  
  void next_generation() { // update the tower
    energy = maxEnergy; // reset energy (could/should depend on remaining resources)
    for (projectile p: projectiles) {
      if (p != null) {
        //  p.killBody(); // not sure if this is necessary with the .clear() below
      }
    }
    projectiles.clear();
  }

  void switchweapon(char k) {
    if (k == '1') {
      activeweapon = 1;
    }
    if (k == '2') {
      activeweapon = 2;
    }
  }
  
  void toggleautofire() {
    autofire = !autofire;
  }
  
  void fire() {
    switch(activeweapon) {
    case 1:
      fire_projectile();
      break;
    case 2:
      drop_rock();
      break;        
    }
  }
  
  /* Firing, dropping rocks, etc. uses up some of the tower's energy */
  
  void fire_projectile() {
    if (energy < 1) {
      return;
    }
    projectile p = new projectile(0, 0, angle, 20); // 20 is the current damage, should be a variable, upgradable
    projectiles.add(p);
    energy-=10;
  }
  
  void drop_rock() {
    float x,y;
    // Try to figure out, given the pixel coordinates of the mouse and the camera position, where in the virtual world the cursor is
    x = cameraX + (cameraZ*sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    y = cameraY + (cameraZ*sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    if (energy < 100) {
      return;
    }
    energy -= 100;
    rock r = new rock((int)x, (int)y);
    rocks.add(r); // rocks is a global list
    
  }
}
