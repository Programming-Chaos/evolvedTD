class tower {
  int energy;           // regained by keeping resources, used to defend (fire weapons, etc.)
  int energyGain;       // energy gain per timestep
  int maxEnergy = 1000; // max energy the tower can have
  int activeweapon;     // value determines which weapon is active
  ArrayList<projectile> projectiles;  // list of active projectiles
  float angle = 0;    // angle of tower's main, auto-fir weapon
  float angle_incr = radians(10);
  float goal_angle;
  boolean autofire = true;
  int autofirecounter;  // don't want to autofire every timestep - uses up energy too fast
  PImage gun;    // declare image for gun
  PImage gunalt; // declare alternate image for animation
  PImage gunbase; // gun base
  boolean showgun = true; // show base gun image
  boolean showgunalt = false; // show alternate gun image
  int imagetimer; // timer for alternating gun images
  int soundtimer;
  int radius = 80;
  int targetMode = 1;
  Body tower_body;
  
  // constructor function, initializes the tower
  tower() {
    energy = maxEnergy;
    energyGain = 0;  // should be determined by upgrades, can start at 0
    activeweapon = 1;
    projectiles = new ArrayList<projectile>();
    angle = 0;
    gunbase = loadImage("assets/Tower_base_02.png");
    gun = loadImage("assets/RailGun-01.png");
    gunalt = loadImage("assets/RailGun-a-01.png");
    imagetimer = 0;
    soundtimer = 0;
    
    BodyDef bd = new BodyDef();
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(0, 17)));
    bd.type = BodyType.STATIC;
    bd.linearDamping = 0.9;
    
    tower_body = box2d.createBody(bd);
    // Define the shape -- a  (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.filter.categoryBits = 2; // food is in filter category 2
    fd.filter.maskBits = 65531; // doesn't interact with projectiles 
    fd.shape = sd;
    fd.density = 100;
    tower_body.createFixture(fd);
    
    tower_body.setUserData(this);
  }
  
  void update() {
    update_projectiles();
    if (state == State.RUNNING){
      energy += energyGain;  // gain energy
      if (autofire) {
        Vec2 target;
        autofirecounter++;
//        if(autofirecounter % 20 == 0){
          target = the_pop.vec_to_random_creature(); // target a random creature 
//            target = the_pop.closest(new Vec2(0,0)); // target the closest creature
          if (targetMode == 2){
            target = the_pop.closest(new Vec2(0,0)); // target the closest creature
          }
          if (targetMode == 3){
            target = the_pop.highestAlpha(); 
          }  
//          goal_angle = atan2(target.y,target.x);          
//          if(angle_incr % angle != 0){
//          angle_incr += radians(10);
//          }
        if (autofirecounter % 20 == 0) { // only autofire every 20th time step
          fire();
          autofirecounter = 0;  // reset the counter
          angle = goal_angle;
          goal_angle = atan2(target.y,target.x); 
        }
          
//        }

        if(angle != goal_angle){
          angle += angle_incr;
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
    // display resources, now in player
    /*
    pushMatrix();
    hint(DISABLE_DEPTH_TEST);
      translate(cameraX, cameraY,cameraZ-400);  // centered and below the camera
      fill(0,0,0,200);
      textSize(8);
      text("Resources: "+(int)resources,0.2*width,-0.25*height); 
    hint(ENABLE_DEPTH_TEST); 
    popMatrix();
    */
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
  
  void switchtargetMode(char k) {
    if (k == '3'){
      targetMode = 2;
    }
    if (k == '4'){
      targetMode = 3;
    }
  }
  
  /* Firing, dropping rocks, etc. uses up some of the tower's energy */
  
  void fire_projectile() {
    if (energy < 10) {
      return;
    }
    projectile p = new projectile(0, 0, goal_angle, 20); // 20 is the current damage, should be a variable, upgradable
    projectiles.add(p);
    energy-=10;
    imagetimer = 0;
    soundtimer++;
    if (soundtimer%3==0){
      soundtimer = 0;
      if (playSound) {
        gunshot.rewind();
        gunshot.play();
      }
    }
    else{
      if (playSound) {
        gunshotalt.rewind();
        gunshotalt.play();
      }
    }
  }
  
  void wave_fire(){
    if(energy < 5){
      return;
    }
    for(float a = 0; a < 2*PI ; a += ((2*PI)/20)){
      projectile p = new projectile(5*cos(a), 5*sin(a), a, 20); // 20 is the current damage, should be a variable, upgradable
      // postions of new projectives are not at 0,0 to avoid collisions.
      projectiles.add(p);
    }
    energy-=5;
    imagetimer = 0;
    if (playSound) {
      gunshot.rewind();
      gunshot.play();
    }
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
