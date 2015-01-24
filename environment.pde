
/* The environment is divided into cells.
 * Each cell has a type (an int).
 * A cell may also contain a creature, food, rock, etc.
 * This is done to make sensing efficient - a creature can snese whether there's food (for example) in a cell.
 */

int cellWidth = 20;
int cellHeight = 20;
int maxscent = 255;

class environment{
  int environWidth;
  int environHeight;
  PGraphics image;
  //  PGraphics imageFood;
  int[][] environ;
  boolean[][] foodpresent;      // is there food in a cell
  boolean[][] sensing;          // used for debugging, show which cell is being sensed
  boolean[][] rockpresent;      // is there a rock present
  creature[][] creaturepresent; // is there a creature present
  float[][] scent;              // scent of food, which disperses
  
 
  environment() {
    environWidth = worldWidth / cellWidth;
    environHeight = worldHeight / cellHeight;
    environ = new int[environWidth][environHeight];         // environment type
    foodpresent = new boolean[environWidth][environHeight]; // whether food is in a square
    sensing = new boolean[environWidth][environHeight];     // used for debuging to tell which squares are being sensed
    rockpresent = new boolean[environWidth][environHeight];
    scent = new float[environWidth][environHeight];
    creaturepresent = new creature[environWidth][environHeight];
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        environ[i][j] = 200 + (int)random(25);
        foodpresent[i][j] = false; 
        rockpresent[i][j] = false;
        scent[i][j] = 0;
        creaturepresent[i][j] = null; 
        sensing[i][j] = false;
      }
    }
    makeImage();
    // makeImageFood();
    // updateEnvrion();
  }
  
  void place_creature(creature cd, float x, float y) {
    x = (int)((worldWidth*0.5+x-1)/cellWidth);
    y = (int)((worldHeight*0.5+y-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case creature was temporarily bumped out of bounds
    y = (y+environHeight)%environHeight;
    creaturepresent[(int)x][(int)y] = cd;
  }
  
  void update_scent() {
    int range = 1, tempx, tempy;
    float count;
    float[][] temparray;
    temparray = new float[environWidth][environHeight];
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if (foodpresent[x][y]) {
          count = scent[x][y] + 10; // food causes scent to increase
          scent[x][y] = min(count,maxscent); // increase scent up to the max 
        }
        else {
          count = 0;
          for (int rx = -1*range; rx < range+1; rx++) {
            for (int ry = -1*range; ry < range+1; ry++) {
              tempx = x+rx;
              tempy = y+ry;
              tempx = max(min(environWidth-1, tempx), 0);
              tempy = max(min(environHeight-1, tempy), 0);
              count += scent[tempx][tempy];
            }
          }
          count /= 9.0; // scent is average contribution of 9 cells
          //scent[x][y] = count;
        }
        count *= 0.99; // scent decays over time
        temparray[x][y] = count;
      }
    }
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        //scent[x][y] = min(maxscent,temparray[x][y]);
        scent[x][y] = temparray[x][y];
      }
    }
  }
  
  void updateEnvrion() {
    Vec2 p = new Vec2();
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        creaturepresent[i][j] = null; 
        foodpresent[i][j] = false;
        rockpresent[i][j] = false;
      }
    }
    the_pop.set_creatures(); // the_pop() is a global, set_creatures() tells the environment where each creature is.
    int x, y;
    for (rock r: rocks) {
      p = r.get_pos();
      x = (int)((worldWidth*0.5+p.x-1)/cellWidth);
      y = (int)((worldHeight*0.5+p.y-1)/cellHeight);
      x = (x+environWidth)%environWidth; // in case creature was temporarily bumped out of bounds
      y = (y+environHeight)%environHeight;
      rockpresent[x][y] = true;
    }
    
    for (food fd: foods) {
      p = fd.get_pos();
      if (fd != null && p != null) {
        x = (int)((worldWidth*0.5+p.x-1)/cellWidth);
        y = (int)((worldHeight*0.5+p.y-1)/cellHeight);
        x = (x+environWidth)%environWidth; // in case ccreature was temporarily bumped out of bounds
        y = (y+environHeight)%environHeight;
        foodpresent[x][y] = true;
      }
    }
    update_scent();
  }
  
  int checkForFood(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    sensing[x][y] = true; // so sensed squares can be drawn for debugging purposes
    if (foodpresent[x][y]) {
      return 1;
    }
    return 0;
  }
  
  float getScent(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    sensing[x][y] = true; // so sensed squares can be drawn for debugging purposes
    return scent[x][y];
  }
  
  int checkForCreature(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    if (creaturepresent[x][y] == null) {
      return 0;
    }
    return 1;
  }
  
  int checkForRock(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    if (rockpresent[x][y]) {
      return 1;
    }
    return 0;
  }
  
  void display() {
    updateEnvrion();
    pushMatrix();
    translate(worldWidth*-0.5, worldHeight*-0.5, -1);
    image(image, 0, 0); 
    popMatrix();
    rectMode(CORNER);
    float offsetx = -0.5*worldWidth;// - cellWidth*0.5;
    float offsety = -0.5*worldHeight;// - cellHeight*0.5;
   
    noFill();
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        if (creaturepresent[i][j] != null) {
          stroke(255, 0, 0);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
        }
        /*  debug code to make sure the correct cells are marked as food present
            if (foodpresent[i][j]) {  
            stroke(0, 255, 0);
            rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
            }
        */
        if (rockpresent[i][j]) {
          stroke(0, 0, 0);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
        }
        if (sensing[i][j]) {
          stroke(0, 0, 255);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
          sensing[i][j] = false;
        }
      }
    }
    display_scent();
  }
  
  void display_scent() {
    float size = cellWidth;
    float offset = 0;// cellWidth*0.5;
    pushMatrix();
    translate(worldWidth*-0.5, worldHeight*-0.5, -1);
    noStroke();
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        fill(225, 165, 0, 255*scent[x][y]/maxscent);
        /* code that colors cells with any non-zero scent - shows that scent spreads very far
           if (scent[x][y] > 0) {
           fill(100, 100, 100);
           }
           else {
           fill(100, 100, 100, 0);
           }
        */
          
        rect(offset, offset, size, size);
        translate(cellWidth, 0);
      }
      translate(worldWidth*-1, cellHeight);
    }
    popMatrix();  
  }
  
  void makeImage() { // creates a PImage of the environment instead having to draw each square individually
    image = createGraphics(worldWidth, worldHeight);
    image.beginDraw();
    image.noStroke();
    image.rectMode(CORNER);
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        image.fill(0, environ[i][j], 0);
        image.rect(j*cellWidth, i*cellHeight, cellWidth, cellHeight);
      }
    }
    image.endDraw();
  }
}
