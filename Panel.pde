static int ZOOMED_HEIGHT = 2500;
static int ZOOMED_WIDTH = 2500;
static int ZOOMED_OFFSET = 2163;  // (translate(cameraX, cameraY, cameraZ - zoomOffset)

interface ButtonPress {
  void pressed();
}

class Button {
  float button_height;
  float button_width;
  float button_x;
  float button_y;
  String button_text;
  int textsize;
  ButtonPress BP;
  Panel parent;
  
  Button(float bw, float bh, float bx, float by, String bt, int ts, Panel pr, ButtonPress BPin) {
    button_width = bw;
    button_height = bh;
    button_x = bx;
    button_y = by;
    button_text = bt;
    textsize = ts;
    parent = pr;
    BP = BPin;
  }
  
  void display() {
    fill(255,0,0,150);
    rect(button_x,button_y,button_width,button_height);
    textSize(textsize);
    textAlign(CENTER,CENTER);
    fill(0,0,0,200);
    text(button_text,button_x,button_y,button_width,button_height);
  }
  
  boolean isMouseOver() {
    return (mouseX <= (((float)width/ZOOMED_WIDTH)*((parent.panel_x+(ZOOMED_WIDTH/2))+button_x+(button_width/2))) &&
            mouseX >= (((float)width/ZOOMED_WIDTH)*((parent.panel_x+(ZOOMED_WIDTH/2))+button_x-(button_width/2))) &&
            mouseY <= (((float)width/ZOOMED_WIDTH)*((parent.panel_y+(ZOOMED_HEIGHT/2))+button_y+(button_height/2))) &&
            mouseY >= (((float)width/ZOOMED_WIDTH)*((parent.panel_y+(ZOOMED_HEIGHT/2))+button_y-(button_height/2))));
  }
  
  void buttonPressed() {
    buttonpressed = true;
    BP.pressed();
  }
}

class TextBox {
  float textbox_width;
  float textbox_height;
  float textbox_x;
  float textbox_y;
  String textbox_text;
  int textsize;
  Panel parent;
  
  TextBox(float tw, float th, float tx, float ty, String tt, int ts, Panel pr) {
    textbox_width = tw;
    textbox_height = th;
    textbox_x = tx;
    textbox_y = ty;
    textbox_text = tt;
    textsize = ts;
    parent = pr;
  }
  
  void display() {
    fill(0,0,0,200);
    textSize(textsize);
    textAlign(CENTER,CENTER);
    fill(0,0,0,200);
    text(textbox_text,textbox_x,textbox_y,textbox_width,textbox_height);
  }
}

class Panel {
  float panel_width;
  float panel_height;
  float panel_x;
  float panel_y;
  boolean hiddenpanel;
  boolean enabled;
  boolean shown;
  float offsetX;
  float offsetY;
  float current_offsetX;
  float current_offsetY;
  int direction;
  ArrayList<Button> buttons = new ArrayList<Button>();
  ArrayList<TextBox> textboxes = new ArrayList<TextBox>();
  
  Panel(float pw, float ph, float px, float py, boolean hp) {
    panel_width = pw;
    panel_height = ph;
    panel_x = px;
    panel_y = py;
    hiddenpanel = hp;
    enabled = false;
    if (hiddenpanel) {
      shown = false;
      if (panel_x > panel_y)
        if ((-1*panel_x) > panel_y)
          direction = 0;
        else
          direction = 1;
      else
        if ((-1*panel_x) > panel_y)
          direction = 3;
        else
          direction = 2;
      switch (direction) {
        case 0:
          offsetX = 0;
          offsetY = ((-1*((panel_y+(ZOOMED_HEIGHT/2))+(panel_height/2)))+5);
          current_offsetX = 0;
          current_offsetY = offsetY;
          break;
        case 1:
          offsetX = ((((ZOOMED_WIDTH/2)-panel_x)+(panel_width/2))-5);
          offsetY = 0;
          current_offsetX = offsetX;
          current_offsetY = 0;
          break;
        case 2:
          offsetX = 0;
          offsetY = ((((ZOOMED_HEIGHT/2)-panel_y)+(panel_height/2))-5);
          current_offsetX = 0;
          current_offsetY = offsetY;
          break;
        case 3:
          offsetX = ((-1*((panel_x+(ZOOMED_WIDTH/2))+(panel_width/2)))+5);
          offsetY = 0;
          current_offsetX = offsetX;
          current_offsetY = 0;
          break;
      }
    }
    else shown = true;
  }
  
//  x = cameraX + (cameraZ * sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
//  y = cameraY + (cameraZ * sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15

  void display() {
    if (!enabled)return;
    if (shown) {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
        translate(cameraX+panel_x, cameraY+panel_y,cameraZ-ZOOMED_OFFSET);  // centered and below the camera+180+panel_x
        fill(255,255,255,150);
        rect(0,0,panel_width,panel_height);
        for (Button b : buttons)
          b.display();
        for (TextBox t : textboxes)
          t.display();
        /*fill(0,0,0,255);
        textSize(8);
        text("Resources: " + (int)the_player.resources,-0.45*panel_width,-0.40*panel_height); 
        text("Generation: " + generation,-0.45*panel_width,-0.3*panel_height); 
        text("Time left: " + (timepergeneration-timesteps),-0.45*panel_width,-0.2*panel_height); 
        fill(255,0,0,200);
        // sample button
        rect(0,0.4*panel_height, panel_width*0.9, panel_height*0.1);  
        fill(0,0,0,200);
        text("Wave Fire", -0.2*panel_width,0.43*panel_height);*/
      hint(ENABLE_DEPTH_TEST); 
      popMatrix();
    }
    else if (hiddenpanel) {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
        translate(cameraX+panel_x+current_offsetX, cameraY+panel_y+current_offsetY,cameraZ-ZOOMED_OFFSET);
        fill(255,255,255,150);
        rect(0,0,panel_width,panel_height);
      hint(ENABLE_DEPTH_TEST); 
      popMatrix();
    }
  }
  
  void update() {
    if (!enabled)return;
    if (hiddenpanel) {
      if (isMouseNear()) {
        if (!shown) {
          if (direction == 0 || direction == 2) {
            current_offsetY -= (offsetY*0.1);
            if(current_offsetY == 0)shown = true;
          }
          else {
            current_offsetX -= (offsetX*0.1);
            if(current_offsetX == 0)shown = true;
          }
        }
      }
      else if (current_offsetX != offsetX || current_offsetY != offsetY) {
        if (direction == 0 || direction == 2) {
          current_offsetY += (offsetY*0.1);
          if (shown)shown = false;
        }
        else {
          current_offsetX += (offsetX*0.1);
          if (shown)shown = false;
        }
      }
    }
  }
  
  boolean isMouseNear() {
    return ((mouseX <= (((float)width/ZOOMED_WIDTH)*((panel_x+(ZOOMED_WIDTH/2))+(panel_width/2)))) &&
            (mouseX >= (((float)width/ZOOMED_WIDTH)*((panel_x+(ZOOMED_WIDTH/2))-(panel_width/2)))) &&
            (mouseY <= (((float)width/ZOOMED_WIDTH)*((panel_y+(ZOOMED_HEIGHT/2))+(panel_height/2)))) &&
            (mouseY >= (((float)width/ZOOMED_WIDTH)*((panel_y+(ZOOMED_HEIGHT/2))-(panel_height/2)))));
  }
  
  void mouse_pressed() {
    if (!enabled)return;
    for (Button b : buttons)
      if (b.isMouseOver())b.buttonPressed();
  }
  
  int createButton(float bw, float bh, float bx, float by, String bt, int ts, ButtonPress BP) {
    buttons.add(new Button(bw,bh,bx,by,bt,ts,this,BP));//bw,bh,bx,by,bt,this,BP));
    return (buttons.size() - 1); // return the index of this button for later reference
  }
  
  int createTextBox(float tw, float th, float tx, float ty, String tt, int ts) {
    textboxes.add(new TextBox(tw,th,tx,ty,tt,ts,this));//bw,bh,bx,by,bt,this,BP));
    return (buttons.size() - 1); // return the index of this button for later reference
  }
}
