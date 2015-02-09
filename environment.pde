
/* The environment is divided into cells.
 * Each cell has a type (an int).
 * A cell may also contain a creature, food, rock, etc.
 * This is done to make sensing efficient - a creature can sense whether there's food (for example) in a cell.
 */

int cellWidth = 20;
int cellHeight = 20;
int maxscent = 255;

class tile {
  int coloring;      // 0 to 255 value that describes tile visually
  int weathering;    // 0 to 255 value that describes tile weathering visually
  int viscosity;     // 0 (solid) to 255 (water) value that describes the viscosity
                       // of a tile and determines whether the tile can be considered
                       // liquid
  
  float scent;         // how much scent is present
  
  boolean isLiquid;    // is the cell traversable as a liquid
  boolean hasFood;     // is there food present
  boolean hasRock;     // is there a rock present
  boolean hasScent;    // is scent present
  boolean hasTower;    // is there a tower present
  
  creature hasCreature; // is there a creature present

  boolean DEBUG_sensing; // for debugging
  
  // FUNC
  tile() {
    coloring = 0;
    weathering = 0;
    viscosity = 0;
    scent = 0;
    isLiquid = false;
    hasFood = false;
    hasRock = false;
    hasTower = false;
    hasCreature = null;
    
    DEBUG_sensing = false;
  }
  
  // GET
  int getColor()           { return coloring; }
  int getWeather()         { return weathering; }
  int getViscosity()       { return viscosity; }
  float getScent()         { return scent; }
  boolean isLiquid()       { return isLiquid; }
  boolean hasFood()        { return hasFood; }
  boolean hasRock()        { return hasRock; }
  boolean hasTower()       { return hasTower; }
  creature hasCreature()   { return hasCreature; }
  
  boolean DEBUG_sensing()  { return DEBUG_sensing; }
  
  // SET
  void setColor(int c)           { coloring = c; }
  void setWeather(int w)         { weathering = w; }
  void setViscosity(int v)       { viscosity = v; }
  void setScent(float s)         { scent = s; }
  void isLiquid(boolean l)       { isLiquid = l; }
  void hasFood(boolean f)        { hasFood = f; }
  void hasRock(boolean r)        { hasRock = r; }
  void hasTower(boolean t)       { hasTower = t; }
  void hasCreature(creature c)   { hasCreature = c; }

  void DEBUG_sensing(boolean s)  { DEBUG_sensing = s; } 
}

class environment{
  int environWidth;
  int environHeight;
  int environAltitude;
  float temp; // celsius
  PGraphics image;
  
  tile[][] tileMap;
 
  environment() {
    environWidth = worldWidth / cellWidth;
    environHeight = worldHeight / cellHeight;   
    environAltitude = (int)random(255);
    temp = environAltitude - (int)random(30) - 200; 
    
    tileMap = new tile[environHeight][environWidth];
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        tileMap[i][j] = new tile();
        tileMap[i][j].setColor(200 + (int)random(25));    // environment type
        tileMap[i][j].setWeather(0);                      // weather type
        tileMap[i][j].setViscosity(0);                    // how viscous the tile is;
        tileMap[i][j].setScent(0);
        tileMap[i][j].isLiquid(false);                    // viscosity > 200 liquid = true
        tileMap[i][j].hasCreature(null);                 
        tileMap[i][j].hasFood(false); 
        tileMap[i][j].hasRock(false);
        tileMap[i][j].hasTower(false);
         
        tileMap[i][j].DEBUG_sensing(false);    // used for debugging to tell which squares are being sensed
      }
    }
    
    generateWater(5, 10, 3);
    makeImage();
    // makeImageFood();
    // updateEnvrion();
  }

  void generateWater(int numWaterBodies, int initialSize, int deltaSize) {
    int totalSize = 0;
    int x = 0;
    int y = 0;
    for(int i = 0; i < numWaterBodies; i++) {
      // water body origin
      x = (int)random(environWidth);
      y = (int)random(environHeight);
      
      totalSize = initialSize + ((int)random(deltaSize) * (int)random(-1, 1)); // noted extra chance of delta being 0
      
      x = x + (totalSize / 2);
      y = y + (totalSize / 2);
      
      
      int a, b, r;
      for(int xOffset = x - (totalSize / 2); xOffset < (x + (totalSize / 2)); xOffset++) {
        for(int yOffset = y - (totalSize / 2); yOffset < (y + (totalSize / 2)); yOffset++) {
          a = xOffset - x;
          b = yOffset - y;
          r = (totalSize / 2);
          if(xOffset < environWidth && yOffset < environHeight && xOffset > 0 && yOffset > 0) {
            if((a * a) + (b * b) <= (r * r) ){  
              tileMap[xOffset][yOffset].isLiquid(true);
              tileMap[xOffset][yOffset].setViscosity(255);
            }
          }  
        }  
      }
    }
  }  
  
  void place_creature(creature cd, float x, float y) {
    x = (int)((worldWidth*0.5+x-1)/cellWidth);
    y = (int)((worldHeight*0.5+y-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case creature was temporarily bumped out of bounds
    y = (y+environHeight)%environHeight;
    tileMap[(int)x][(int)y].hasCreature(cd);
  }
  
  void update_scent() {
    int range = 1, tempx, tempy;
    float count;
    float[][] temparray;
    temparray = new float[environWidth][environHeight];
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if (tileMap[x][y].hasFood()) {
          count = tileMap[x][y].getScent() + 10; // food causes scent to increase
          tileMap[x][y].setScent(min(count,maxscent)); // increase scent up to the max 
        }
        else {
          count = 0;
          for (int rx = -1*range; rx < range+1; rx++) {
            for (int ry = -1*range; ry < range+1; ry++) {
              tempx = x+rx;
              tempy = y+ry;
              tempx = max(min(environWidth-1, tempx), 0);
              tempy = max(min(environHeight-1, tempy), 0);
              count += tileMap[tempx][tempy].getScent();
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
        tileMap[x][y].setScent(temparray[x][y]);
      }
    }
  }
  
  void updateEnviron() {
    Vec2 p = new Vec2();
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        tileMap[i][j].hasCreature(null); 
        tileMap[i][j].hasFood(false);
        tileMap[i][j].hasRock(false);
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
      tileMap[x][y].hasRock(true);
    }
    
    for (food fd: foods) {
      p = fd.get_pos();
      if (fd != null && p != null) {
        x = (int)((worldWidth*0.5+p.x-1)/cellWidth);
        y = (int)((worldHeight*0.5+p.y-1)/cellHeight);
        x = (x+environWidth)%environWidth; // in case ccreature was temporarily bumped out of bounds
        y = (y+environHeight)%environHeight;
        tileMap[x][y].hasFood(true);
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
    tileMap[x][y].DEBUG_sensing(true); // so sensed squares can be drawn for debugging purposes
    if (tileMap[x][y].hasFood()) {
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
    tileMap[x][y].DEBUG_sensing(true); // so sensed squares can be drawn for debugging purposes
    return tileMap[x][y].getScent();
  }
  
  int checkForCreature(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    if (tileMap[x][y].hasCreature() == null) {
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
    if (tileMap[x][y].hasRock()) {
      return 1;
    }
    return 0;
  }
  
  void display() {
    updateEnviron();
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
        if (tileMap[i][j].hasCreature() != null) {
          stroke(255, 0, 0);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
        }
        /*  debug code to make sure the correct cells are marked as food present
            if (foodpresent[i][j]) {  
            stroke(0, 255, 0);
            rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
            }
        */
        if (tileMap[i][j].hasRock()) {
          stroke(0, 0, 0);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
        }
        if (tileMap[i][j].DEBUG_sensing()) {
          stroke(0, 0, 255);
          rect(offsetx+i*cellHeight, offsety+j*cellWidth, cellHeight, cellWidth);
          tileMap[i][j].DEBUG_sensing(false);
        }
      }
    }
    display_scent();
    display_water();
  }
  
  void display_water() {
    float size = cellWidth;
    float offset = 0;
    pushMatrix();
    translate(worldWidth * -0.5, worldHeight * -0.5, -1);
    noStroke();
    
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if(tileMap[x][y].isLiquid()) {
          fill(0, 0, 255);
          rect(offset, offset, size, size);
        }
        translate(cellWidth, 0);
      }  
      translate(worldWidth*-1, cellHeight);  
    }
    popMatrix();  
  }
  
  void display_scent() {
    float size = cellWidth;
    float offset = 0;// cellWidth*0.5;
    pushMatrix();
    translate(worldWidth*-0.5, worldHeight*-0.5, -1);
    noStroke();
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        fill(225, 165, 0, 255 * tileMap[x][y].getScent() / maxscent);
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
        image.fill(0, tileMap[i][j].getColor(), 0);
        image.rect(j*cellWidth, i*cellHeight, cellWidth, cellHeight);
      }
    }
    image.endDraw();
  }
}
