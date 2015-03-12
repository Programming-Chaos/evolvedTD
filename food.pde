class food {
  Body the_food;
  int radius;
  boolean remove = false;
  
  food(int x, int y) {
    radius = 3;
    makebody(x, y);
    the_food.setUserData(this);
  }
  
  food() {
    radius = 3;
    makebody((int)random(-0.5*worldWidth, 0.5*worldWidth),
             (int)random(-0.5*worldHeight, 0.5*worldHeight));
    the_food.setUserData(this);
  }
  
  food(float x, float y) {
    radius = 3;
    makebody((int)x, (int)y);
    the_food.setUserData(this);
  }
  
  // This function removes the particle from the box2d world
  void killBody() {
    box2d.destroyBody(the_food);
  }
  
  void setRemove(boolean x) {
    remove = x;
  }
  
  int update() { // the only update action is, if remove was set to true by a collision then kill the box2d body and return 1 to have the food removed from the list of food
    if (remove) {
      killBody();
      return 1;
    }
    return 0;
  }
  
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(the_food));
  }
  
  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(the_food);
    //   pushMatrix();
    //   translate(pos.x,pos.y);
    fill(200,0,100);
    stroke(0);
    ellipse(pos.x, pos.y, radius*2, radius*2);
    drawFoodScent(pos.x, pos.y);
    //   popMatrix();
  }

  void drawFoodScent( float x, float y ) {
    noStroke();
    float h = 1.0;
      for (int r = 0; r < 140; r+=20) {
        fill(225, 165, 0, 255 * h);
        ellipse(x, y, r, r);
        h = h * 0.8;
    }
  }
  
  void makebody(int x, int y) {
    BodyDef bd = new BodyDef();
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    bd.type = BodyType.DYNAMIC;
    bd.linearDamping = 0.9;
    
    the_food = box2d.createBody(bd);
    // Define the shape -- a  (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    // collision filters so food/resources won't collide with projectiles
    fd.filter.categoryBits = 2; // food is in filter category 2
    fd.filter.maskBits = 65531; // doesn't interact with projectiles 
    fd.shape = sd;
    fd.density = 1;
    the_food.createFixture(fd);
  }
}
