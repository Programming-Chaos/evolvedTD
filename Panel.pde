interface ButtonPress {
  void pressed();
}

interface StringPass {
  String passed();
}

class Button {
  float button_height;
  float button_width;
  float button_x;
  float button_y;
  String button_text;
  int textsize;
  int red, green, blue;
  ButtonPress BP;
  Panel parent;
  boolean grayed;
  boolean enabled;
  
  Button(float bw, float bh, float bx, float by, String bt, int ts, int r, int g, int b, Panel pr, ButtonPress BPin) {
    button_width = bw;
    button_height = bh;
    button_x = bx;
    button_y = by;
    button_text = bt;
    textsize = ts;
    red = r;
    green = g;
    blue = b;
    parent = pr;
    BP = BPin;
    grayed = false;
    enabled = true;
  }
  
  void display() {
    if (!enabled)return;
    if (grayed) {
      float avgcolor = ((red+green+blue)/3);
      fill(avgcolor,150);
      stroke(0);
      rect(button_x,button_y,button_width,button_height,5);
      stroke(0,0);
      textSize(textsize);
      textAlign(CENTER,CENTER);
      fill((avgcolor<64 ? 255 : 0),255);
      text(button_text,button_x,button_y,button_width,button_height);
    }
    else {
      fill(red,green,blue,150);
      stroke(0);
      rect(button_x,button_y,button_width,button_height,20);
      stroke(0,0);
      textSize(textsize);
      textAlign(CENTER,CENTER);
      fill(((red < 64 && green < 64 && blue < 64) ? 255 : 0), 255);
      text(button_text,button_x,button_y,button_width,button_height);
    }
  }
  
  boolean isMouseOver() {
    return (mouseX <= (((float)width/worldWidth)*((parent.panel_x+(worldWidth/2))+button_x+(button_width/2))) &&
            mouseX >= (((float)width/worldWidth)*((parent.panel_x+(worldWidth/2))+button_x-(button_width/2))) &&
            mouseY <= (((float)width/worldWidth)*((parent.panel_y+(worldHeight/2))+button_y+(button_height/2))) &&
            mouseY >= (((float)width/worldWidth)*((parent.panel_y+(worldHeight/2))+button_y-(button_height/2))));
  }
  
  void buttonPressed() {
    if (!enabled)return;
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
  StringPass SP = null;
  Panel parent;
  int align_horiz;
  int align_vert;
  boolean bordered;
  boolean grayed;
  
  TextBox(float tw, float th, float tx, float ty, String tt, int ts, Panel pr, int ah, int av, boolean b) {
    textbox_width = tw;
    textbox_height = th;
    textbox_x = tx;
    textbox_y = ty;
    textbox_text = tt;
    textsize = ts;
    parent = pr;
    align_horiz = ah;
    align_vert = av;
    bordered = b;
    grayed = false;
  }
  
  TextBox(float tw, float th, float tx, float ty, StringPass SPin, int ts, Panel pr, int ah, int av, boolean b) {
    textbox_width = tw;
    textbox_height = th;
    textbox_x = tx;
    textbox_y = ty;
    SP = SPin;
    textsize = ts;
    parent = pr;
    align_horiz = ah;
    align_vert = av;
    bordered = b;
    grayed = false;
  }
  
  void display() {
    textSize(textsize);
    textAlign(align_horiz,align_vert);
    if (bordered) {
      stroke(0);
      fill(255,255,255,0);
      rect(textbox_x, textbox_y, textbox_width, textbox_height, 5);
      stroke(0,0);
    }
    fill(0,0,0,255);
    if (textbox_width == 0 && textbox_height == 0) {
      if (SP == null) text(textbox_text,textbox_x,textbox_y);
      else {
        text(SP.passed(),textbox_x,textbox_y);
      }
    }
    else {
      if (SP == null) text(textbox_text,textbox_x,textbox_y,textbox_width,textbox_height);
      else {
        text(SP.passed(),textbox_x,textbox_y,textbox_width,textbox_height);
      }
    }
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
  int opacity;
  ArrayList<Button> buttons = new ArrayList<Button>();
  ArrayList<TextBox> textboxes = new ArrayList<TextBox>();

  // used by setupTextBox and pushTextBox
  float listed_textbox_x;
  float listed_textbox_y;
  float listed_textbox_height; // increment in height for each push
  int listed_textbox_textsize;
  int listed_textbox_i;

  Panel(float pw, float ph, float px, float py, boolean hp) {
    panel_width = pw;
    panel_height = ph;
    panel_x = px;
    panel_y = py;
    hiddenpanel = hp;
    opacity = 150;
    construct();
  }

  Panel(float pw, float ph, float px, float py, boolean hp, int o) {
    panel_width = pw;
    panel_height = ph;
    panel_x = px;
    panel_y = py;
    hiddenpanel = hp;
    opacity = o;
    construct();
  }
  
  void construct() {
    enabled = true;
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
          offsetY = ((-1*((panel_y+(worldHeight/2))+(panel_height/2)))+5);
          current_offsetX = 0;
          current_offsetY = offsetY;
          break;
        case 1:
          offsetX = ((((worldWidth/2)-panel_x)+(panel_width/2))-5);
          offsetY = 0;
          current_offsetX = offsetX;
          current_offsetY = 0;
          break;
        case 2:
          offsetX = 0;
          offsetY = ((((worldHeight/2)-panel_y)+(panel_height/2))-5);
          current_offsetX = 0;
          current_offsetY = offsetY;
          break;
        case 3:
          offsetX = ((-1*((panel_x+(worldWidth/2))+(panel_width/2)))+5);
          offsetY = 0;
          current_offsetX = offsetX;
          current_offsetY = 0;
          break;
      }
    }
    else shown = true;
    panels.add(this);
  }
  
  //  x = cameraX + (cameraZ * sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
  //  y = cameraY + (cameraZ * sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15

  void display() {
    if (!enabled)return;
    if (shown) {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
        translate(cameraX+panel_x, cameraY+panel_y,cameraZ-zoomOffset);  // centered and below the camera+180+panel_x
        fill(200,200,200,opacity);
        noStroke();
        rect(0,0,panel_width,panel_height, 10);
        for (Button b : buttons)
          b.display();
        for (TextBox t : textboxes)
          t.display();
      hint(ENABLE_DEPTH_TEST); 
      popMatrix();
    }
    else if (hiddenpanel) {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
        translate(cameraX+panel_x+current_offsetX, cameraY+panel_y+current_offsetY,cameraZ-zoomOffset);
        fill(200,200,200,opacity);
        noStroke();
        rect(0,0,panel_width,panel_height, 10);
      hint(ENABLE_DEPTH_TEST); 
      popMatrix();
    }
  }
  
  void update() {
    if (!enabled)return;
    if (state != State.RUNNING)return;
    if (!hiddenpanel)return;
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
    else {
      if (shown)shown = false;
      if (current_offsetX != offsetX || current_offsetY != offsetY) {
        if (direction == 0 || direction == 2)
          current_offsetY += (offsetY*0.1);
        else
          current_offsetX += (offsetX*0.1);
      }
    }
  }
  
  boolean isMouseNear() {
    return ((mouseX <= (((float)width/worldWidth)*((panel_x+(worldWidth/2))+(panel_width/2)))) &&
            (mouseX >= (((float)width/worldWidth)*((panel_x+(worldWidth/2))-(panel_width/2)))) &&
            (mouseY <= (((float)width/worldWidth)*((panel_y+(worldHeight/2))+(panel_height/2)))) &&
            (mouseY >= (((float)width/worldWidth)*((panel_y+(worldHeight/2))-(panel_height/2)))));
  }
  
  boolean mouse_pressed() {
    if (!enabled)return false;
    for (Button b : buttons)
      if (b.isMouseOver() && !b.grayed) {
        b.buttonPressed();
        return true;
      }
    return false;
  }
  
  int createButton(float bw, float bh, float bx, float by, String bt, int ts, ButtonPress BP) {
    buttons.add(new Button(bw,bh,bx,by,bt,ts,0,0,128,this,BP));//default color navy blue
    return (buttons.size() - 1); // return the index of this button for later reference
  }
  
  int createButton(float bw, float bh, float bx, float by, String bt, int ts, int r, int g, int b, ButtonPress BP) {
    buttons.add(new Button(bw,bh,bx,by,bt,ts,r,g,b,this,BP));
    return (buttons.size() - 1); // return the index of this button for later reference
  }

  // sets values to be passed to this panel's list of text boxes (every panel gets one) (or none)
  void setupTextBoxList(float tx, float ty, float h, int ts) {
    listed_textbox_x = tx;
    listed_textbox_y = ty;
    listed_textbox_height = h;
    listed_textbox_textsize = ts;
    listed_textbox_i = -1; // so first push starts at 0
  }

  int pushTextBox(String s) {
    return createTextBox(listed_textbox_x,listed_textbox_y+(++listed_textbox_i*listed_textbox_height),s,listed_textbox_textsize);
  }

  int pushTextBox(StringPass SP) {
    return createTextBox(listed_textbox_x,listed_textbox_y+(++listed_textbox_i*listed_textbox_height),SP,listed_textbox_textsize);
  }

  //This is a boxed-style textbox. The text will wrap within the dimensions tw and th (textbox width and textbox height)
  int createTextBox(float tw, float th, float tx, float ty, String tt, int ts) {//tx and ty are the coordinates of the textbox's center (boxed-style)
    textboxes.add(new TextBox(tw,th,tx,ty,tt,ts,this,CENTER,CENTER, false));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }//in boxed-style, the origin of the textbox's coordinates is the center of the panel
  //This is a cornered-style textbox. The text will not wrap. It will just keep going off the page unless you put linebreaks.
  int createTextBox(float tx, float ty, String tt, int ts) {//tx and ty are the coordinates of the topleft corner with the panel's topleft corner as the origin (cornered style)
    textboxes.add(new TextBox(0,0,(tx-(panel_width/2)),(ty-(panel_height/2)),tt,ts,this,LEFT,TOP, false));
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //boxed style with executable string code
  int createTextBox(float tw, float th, float tx, float ty, StringPass SP, int ts) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(tw,th,tx,ty,SP,ts,this,CENTER,CENTER, false));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //cornered style with executable string code
  int createTextBox(float tx, float ty, StringPass SP, int ts) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(0,0,(tx-(panel_width/2)),(ty-(panel_height/2)),SP,ts,this,LEFT,TOP, false));
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //cornered style with executable string code
  int createTextBox(float tx, float ty, StringPass SP, int ts, boolean b) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(0,0,(tx-(panel_width/2)),(ty-(panel_height/2)),SP,ts,this,LEFT,TOP, b));
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //boxed style with a straight-up string and text alignment specifications
  int createTextBox(float tw, float th, float tx, float ty, String tt, int ts, int ah, int av) {//used for hardcoded strings
    textboxes.add(new TextBox(tw,th,tx,ty,tt,ts,this,ah,av, false));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //cornered style with a straight- up string and text alignment specifications
  int createTextBox(float tx, float ty, String tt, int ts, int ah, int av) {//used for hardcoded strings
    textboxes.add(new TextBox(0,0,(tx-(panel_width/2)),(ty-(panel_height/2)),tt,ts,this,ah,av, false));
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //boxed style with with executable string code and text alignment specifications
  int createTextBox(float tw, float th, float tx, float ty, StringPass SP, int ts, int ah, int av) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(tw,th,tx,ty,SP,ts,this,ah,av, false));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //cornered style with executable string code and text alignment specifications
  int createTextBox(float tx, float ty, StringPass SP, int ts, int ah, int av) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(0,0,(tx-(panel_width/2)),(ty-(panel_height/2)),SP,ts,this,ah,av, false));
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }

  //This is a boxed-style textbox. The text will wrap within the dimensions tw and th (textbox width and textbox height)
  int createTextBox(float tw, float th, float tx, float ty, String tt, int ts, boolean b) {//tx and ty are the coordinates of the textbox's center (boxed-style)
    textboxes.add(new TextBox(tw,th,tx,ty,tt,ts,this,CENTER,CENTER, b));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }//in boxed-style, the origin of the textbox's coordinates is the topleft of the panel
  //boxed style with executable string code
  int createTextBox(float tw, float th, float tx, float ty, StringPass SP, int ts, boolean b) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(tw,th,tx,ty,SP,ts,this,CENTER,CENTER, b));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //boxed style with a straight-up string and text alignment specifications
  int createTextBox(float tw, float th, float tx, float ty, String tt, int ts, int ah, int av, boolean b) {//used for hardcoded strings
    textboxes.add(new TextBox(tw,th,tx,ty,tt,ts,this,ah,av, b));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
  //boxed style with with executable string code and text alignment specifications
  int createTextBox(float tw, float th, float tx, float ty, StringPass SP, int ts, int ah, int av, boolean b) {//used when the contents of the textbox contains a variable that will change, and therefore must be accesed every time
    textboxes.add(new TextBox(tw,th,tx,ty,SP,ts,this,ah,av, b));//specifies a size for the text to wrap within
    return (textboxes.size() - 1); // return the index of this textbox for later reference
  }
}
