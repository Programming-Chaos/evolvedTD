class tower {
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int energyGain;       // energy gain per timestep
  int maxEnergy = 1000; // max energy the tower can have
  float resources;        // amount of resources the tower has
  float maxResources;     // max resources the tower can store, may not use, if used should be upgradable
  float resourceGain;     // gain per timestep
  int activeweapon;     // value determines which weapon is active
  ArrayList<projectile> projectiles;  // list of active projectiles
  float angle;    // angle of tower's main, auto-fir weapon
  boolean autofire = true;
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  PImage gun;    // declare image for gun
  PImage gunalt; // declare alternate image for animation
  PImage gunbase; // gun base
  boolean showgun = true; // show base gun image
  boolean showgunalt = false; // show alternate gun image
  int imagetimer; // timer for alternating gun images
  
  // constructor function, initializes the tower
  tower() {
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    activeweapon = 1;
    resourceGain = 0.1;  // changes with upgrades
    projectiles = new ArrayList<projectile>();
    angle = 0;
    gunbase = loadImage("assets/Tower_base_02.png");
    gun = loadImage("assets/Gunturret04a.png");
    gunalt = loadImage("assets/Gunturret04b.png");
    imagetimer = 0;
  }
  
  void update() {
    update_projectiles();
    if(!paused){
      energy += energyGain;  // gain energy
      resources += resourceGain;  // gain resources
      if (autofire) {
        Vec2 target;
        autofirecounter++;
        if (autofirecounter % 20 == 0 & !paused) { // only autofire every Nth time step
        //target = the_pop.closest(new Vec2(0,0)); // target the closest creature
          target = the_pop.vec_to_random_creature(); // target a random creature
          angle = atan2(target.y,target.x);
          fire();
          autofirecounter = 0;  // reset the counter
        }
      }
      else {  // user controlled, point at the mouse
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
  }
  
  void update_projectiles(){
    for (int i = projectiles.size() - 1; i >= 0; i--) {  // walk through particles to avoid missing one
      projectile p = projectiles.get(i);
      p.update();
      if(p.getRemove()){
        p.killBody();  // remove the box2d body
        projectiles.remove(i);  // remove the projectile from the list
      }
    } 
  }
  
  void display() {
    /*
    // draw a line 
    stroke(255, 0, 0);
    line(0, 0, 30*cos(angle), 30*sin(angle));
    //draw the tower
    ellipse(0, 0, 10, 10); // just a circle for now
    */
    image(gunbase,-128,-128);
    showgunalt = false;
    showgun = true;
    imagetimer++;
    if (imagetimer > 2) {
      showgunalt = false;
      showgun = true;
    }
    else {
      showgunalt = true;
      showgun = false;
    }
      pushMatrix();
      float c = angle;
      rotate(c + HALF_PI);
      if(showgun)image(gun,-128,-128);
      if(showgunalt)image(gunalt,-128,-128);
      popMatrix();
    
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
    // display resources
    pushMatrix();
    hint(DISABLE_DEPTH_TEST);
      translate(cameraX, cameraY,cameraZ-400);  // centered and below the camera
      fill(0,0,0,200);
      textSize(8);
      text("Resources: "+(int)resources,0.2*width,-0.25*height); 
    hint(ENABLE_DEPTH_TEST); 
    popMatrix();
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
    imagetimer = 0;
    gunshot.rewind();
    gunshot.play();
    
  }
  
  void drop_rock() {
    float x,y;
    // Try to figure out, given the pixel coordinates of the mouse and the camera position, where in the virtual world the cursor is
    x = cameraX + (cameraZ*sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    y = cameraY + (cameraZ*sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
    if (energy < 100) {
      return;
    }
    energy -= 100;  // uses a lot of energy to drop a rock
    rock r = new rock((int)x, (int)y);
    rocks.add(r); // rocks is a global list
    
  }
}
