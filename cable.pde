class cable {
  int ID;
  char type;
  structure parent;
  int xpos; // x position of center of cable endpoint
  int ypos; // y position of center of cable endpoint
  float radius = 20;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  boolean remove = false;
  cable otherEnd;
  ArrayList<structure> connectedStructures;
  Body terminal_body;
  
  cable(char tp, int id, structure prnt) {
    type = tp;
    ID = id;
    parent = prnt;
    connectedStructures = new ArrayList<structure>();

    xpos = round(mouse_x);
    ypos = round(mouse_y);
  }
  
  void update() {
    if (!inTransit && wasInTransit) { // create a body for a just-placed cable endpoint
      BodyDef bd = new BodyDef();
      bd.position.set(box2d.coordPixelsToWorld(new Vec2(xpos,ypos)));
      bd.type = BodyType.STATIC;
      bd.linearDamping = 0.9;
      terminal_body = box2d.createBody(bd);
      CircleShape sd = new CircleShape();
      sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
      FixtureDef fd = new FixtureDef();
      fd.filter.categoryBits = 2; // food is in filter category 2
      fd.filter.maskBits = 65531; // doesn't interact with projectiles
      fd.shape = sd;
      fd.density = 100;
      terminal_body.createFixture(fd);
      terminal_body.setUserData(this);
      wasInTransit = false;
    }
    if (inTransit) {
      if (!wasInTransit) {
        terminal_body.setUserData(null);
        for (Fixture f = terminal_body.getFixtureList(); f != null; f = f.getNext())
          f.setUserData(null);
        box2d.destroyBody(terminal_body); // destroy the body of a just-picked-up cable endpoint
      }
      wasInTransit = true;
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (structure s : the_player.structures) { //check for overlap with existing structures
        if (s != the_player.pickedup) {
          if (s.type == 'f') {
            if (sqrt((s.f.xpos-xpos)*(s.f.xpos-xpos)+(s.f.ypos-ypos)*(s.f.ypos-ypos)) <= radius*2)
              conflict = true;
          }
          else if (s.type == 't') {
            if (sqrt((s.t.xpos-xpos)*(s.t.xpos-xpos)+(s.t.ypos-ypos)*(s.t.ypos-ypos)) <= radius*2)
              conflict = true;
          }
          else if (s.type == 'c') {
            if (sqrt((s.c.xpos-xpos)*(s.c.xpos-xpos)+(s.c.ypos-ypos)*(s.c.ypos-ypos)) <= radius*2)
              conflict = true;
          }
        }
      } // and check if the farm is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
  }
  
  void display() {
    if (inTransit) {
    // draw the outline of the cable's box2D body
      pushMatrix();
      translate(xpos,ypos);
      fill(0, 0, 0, 0);
      if (conflict) stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
      for (structure s : the_player.structures) { // draw the outlines of all the other structure's bodies
        if (s.ID != the_player.pickedup.ID) {
          pushMatrix();
          if (s.type == 'f') translate(box2d.getBodyPixelCoord(s.f.farm_body).x, box2d.getBodyPixelCoord(s.f.farm_body).y);
          else if (s.type == 't') translate(box2d.getBodyPixelCoord(s.t.tower_body).x, box2d.getBodyPixelCoord(s.t.tower_body).y);
          else if (s.type == 'c') translate(box2d.getBodyPixelCoord(s.c.terminal_body).x, box2d.getBodyPixelCoord(s.c.terminal_body).y);
          fill(0, 0, 0, 0);
          stroke(0);
          ellipse(0, 0, radius*2, radius*2);
          stroke(0);
          popMatrix();
        }
      }
    }
    else if (the_player.selectedStructure != null && the_player.selectedStructure.ID == ID) {
      pushMatrix();
      translate(box2d.getBodyPixelCoord(terminal_body).x, box2d.getBodyPixelCoord(terminal_body).y);
      fill(0, 0, 0, 0);
      stroke(255,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
    }
    pushMatrix();
    stroke(0);
    strokeWeight(1);
    fill(0,0,0,255);
    ellipse(xpos,ypos,radius*2,radius*2);
    popMatrix();
  }
}
