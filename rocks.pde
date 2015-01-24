class rock {
  Body the_rock;
  int radius;
  boolean remove = false;
  
  rock(int x, int y) {
    radius = (int)(10);
    makebody(x, y);
    the_rock.setUserData(this);
  }
  
  rock() {
    radius = (int)(10);
    makebody((int)random(-0.5*worldWidth, 0.5*worldWidth),
             (int)random(-0.5*worldHeight, 0.5*worldHeight));
    the_rock.setUserData(this);
  }
  
  // This function removes the particle from the box2d world
  void killBody() {
    box2d.destroyBody(the_rock);
  }
  
  Vec2 get_pos() {
    return(box2d.getBodyPixelCoord(the_rock));
  }
  
  void setRemove(boolean x) {
    remove = x;
  }
  
  int update() {
    if (remove) {
      killBody();
      return 1;
    }
    return 0;
  }
  
  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(the_rock);
    pushMatrix();
    translate(pos.x, pos.y);
    fill(200, 200, 200);
    stroke(0);
    ellipse(0, 0, radius*2, radius*2);
    popMatrix();
  }
  
  void makebody(int x, int y) {
    BodyDef bd = new BodyDef();
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    bd.type = BodyType.DYNAMIC;
    bd.linearDamping = 0.9;
    
    the_rock = box2d.createBody(bd);
    // Define the shape -- a  (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.shape = sd;
    fd.density = 30;
    the_rock.createFixture(fd);
  }
}
