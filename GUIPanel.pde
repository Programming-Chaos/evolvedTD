
class panel{
  float panel_x;
  float panel_y;
  float panel_height;
  float panel_width;
  boolean extended;
  int paneltype;      // 1 for upper right, 2 for bottom
  PImage gbase;
  PImage g;
  
  panel(int pw, int ph, int type){
    panel_width = pw;// 100;
    panel_height = ph; //100;
    panel_x = panel_width;
    panel_y = panel_height;
    paneltype = type;
    extended = false;
    gbase = loadImage("assets/Tower_base_02.png");
  }
//  x = cameraX + (cameraZ * sin(PI/2.0)*1.15) * ((mouseX-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15
//  y = cameraY + (cameraZ * sin(PI/2.0)*1.15) * ((mouseY-width*0.5)/(width*0.5)) * 0.5; // not sure why 1.15

  void display(){
    pushMatrix();
    hint(DISABLE_DEPTH_TEST);
      switch (paneltype){
        case 1:
          translate(cameraX+180+panel_x, cameraY-180,cameraZ-400);  // centered and below the camera
          fill(255,255,255,150);
          rect(0,0,panel_width,panel_height);
          fill(0,0,0,200);
          textSize(8);
          text("Resources: " + (int)the_player.resources,-0.45*panel_width,-0.40*panel_height); 
          text("Generation: " + generation,-0.45*panel_width,-0.3*panel_height); 
          text("Time left: " + (timepergeneration-timesteps),-0.45*panel_width,-0.2*panel_height); 
          fill(255,0,0,200);
          // sample button
          rect(0,0.4*panel_height, panel_width*0.9, 10);  
          fill(0,0,0,200);
          text("Wave Fire", -0.0*panel_width,0.43*panel_height);
          break;
        case 2:
          g = loadImage("assets/RailGun-01.png");
          //translate(cameraX, cameraY+195+panel_y,cameraZ-400);  // centered and below the camera
          translate(-1250, 1250+panel_y, 0);
          fill(255,255,255,150);
          rect(1250,-125,panel_width,panel_height);
          fill(0,150,0,200);
          rect(0, 0, 500, 500);
          image(gbase, 0, -256);
          image(g, 0, -256);
          break;
      }
    hint(ENABLE_DEPTH_TEST); 
    popMatrix();
  }
  
  void update(){
    switch (paneltype){
      case 1:
        if( (mouseX > width - (panel_width*2)) && (mouseY < (panel_height*2)) && (panel_x > 0) ){
          panel_x = panel_x - (panel_width*0.1);
        }
        if( ((mouseX < width-(panel_width*2)) || (mouseY > (panel_height*2)))  && panel_x < panel_width){
          panel_x += (panel_width*0.1);
        }
        break;
      case 2:
        if( (mouseY > height - (panel_height/2)) && (panel_y > 0)){
         panel_y = panel_y - (panel_height*0.1); 
        }
        if( (mouseY < height - (panel_height/2)) && panel_y < panel_height){
          panel_y += (panel_height*0.1);
        }
        break;
    }
    if(panel_x == 0 || panel_y == 0){
      extended = true;
    }
    else{
      extended = false;
    }
  }
  
  void mouse_pressed(){
    if(!extended){  // only handle mouse presses in an extended panel
      return;
    }
    if(mouseX > (width-panel_width) && mouseX < width){
      if(mouseY > (panel_height*1.3) && mouseY < panel_height*1.9 ){
        the_player.wave_fire();
      }
    }
    
    if((mouseY > height - (panel_height/3))  && mouseX < panel_width/32){
      the_player.wave_fire();
    }
    
  }
}
