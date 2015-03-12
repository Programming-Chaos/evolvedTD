
/* The environment is divided into cells.
 * Each cell has a type (an int).
 * A cell may also contain a creature, food, rock, etc.
 * This is done to make sensing efficient - a creature can sense whether there's food (for example) in a cell.
 */

int cellWidth = 20;
int cellHeight = 20;
int maxscent = 255;

boolean isRaining;     // returns whether or not it is raining

int waitRainOff, waitRainOn; // will wait 1 minute before raining again after stopping
int tempWaitOff, tempWaitOn; // temp time holders to compare againsr waitRain time
int timeStepTemp = timesteps;

int waterReserveMax = 10000; // the world is only allowed to contain a certain amount of water
int waterReserve = int(random(1, 10000)); // start of game water reserve amount

int initializeRain() { return int(random(1,3)); }

class tile {
  float altitude;
  int coloring;      // 0 to 255 value that describes tile visually
  int opacity;
  color colors; 
  int weathering;    // 0 to 255 value that describes tile weathering visually
  int viscosity;     // 0 (solid) to 255 (water) value that describes the viscosity
                       // of a tile and determines whether the tile can be considered
                       // liquid

  int creatureScentColor; // value to set what color the creatures scent is
  
  float scent;         // how much scent is present
  float creatureScent; // how much creature scent is present
  float reproScent;
  float painScent;

  
  boolean isLiquid;    // is the cell traversable as a liquid
  boolean hasFood;     // is there food present
  boolean hasRock;     // is there a rock present
  boolean hasScent;    // is scent present
  boolean hasCreatureScent; // is creature scent present
  boolean hasReproScent;
  boolean hasPainScent;

  boolean hasTower;    // is there a tower present
  
  creature hasCreature; // is there a creature present

  boolean DEBUG_sensing; // for debugging
    
  // FUNC
  tile() {
    altitude = 0;
    coloring = 0;
    opacity = 1;
    colors = color(0, 0, 0, 0);
    weathering = 0;
    viscosity = 10;
    weathering = 0;
    scent = 0;
    creatureScent = 0;
    creatureScentColor = 0;
    isLiquid = false;
    hasFood = false;
    hasRock = false;
    hasTower = false;
    hasCreature = null;
    hasCreatureScent = false;
    
    DEBUG_sensing = false;

  }
  
  // GET
  float getAlt()           { return altitude; }
  int getColor()           { return coloring; }
  int getWeather()         { return weathering; }
  int getViscosity()       { return viscosity; }
  float getScent()         { return scent; }
  boolean isLiquid()       { return isLiquid; }
  boolean hasFood()        { return hasFood; }
  boolean hasRock()        { return hasRock; }
  boolean hasTower()       { return hasTower; }
  creature hasCreature()   { return hasCreature; }
  int getCreatureScentColor() { return creatureScentColor; }
  
  boolean DEBUG_sensing()  { return DEBUG_sensing; }

  float getCreatureScent() {return creatureScent;}
  float getReproScent() {return reproScent;}
  float getPainScent() {return painScent;}  

  
  // SET
  void setAlt(float a)           { altitude = a; }
  void setColor(int c)           { coloring = c; }
  void setWeather(int w)         { weathering = w; }
  void setViscosity(int v)       { viscosity = v; }
  void setScent(float s)         { scent = s; }
  void isLiquid(boolean l)       { isLiquid = l; }
  void hasFood(boolean f)        { hasFood = f; }
  void hasRock(boolean r)        { hasRock = r; }
  void hasTower(boolean t)       { hasTower = t; }
  void hasCreature(creature c)   { hasCreature = c; }

  void setCreatureScent(float s) { creatureScent = s;}
  void setReproScent(float s) { reproScent = s;}
  void setPainScent(float s) { painScent = s;}



  void setCreatureScentColor(int c) { creatureScentColor = c; }

  void DEBUG_sensing(boolean s)  { DEBUG_sensing = s; } 
}

class gravityVector {
  float x;
  float y;
  float z;
    
  gravityVector() {
    x = 0;
    y = 0;
    z = 0;
  }
  
  gravityVector(float a, float b, float c) {
    x = a;
    y = b;
    z = c; 
  }
}

class environment{
  int environWidth;
  int environHeight;
  int environAltitude;
  int rockFrequency;
  float liquidReservior; // Amount of water the environment is holding to expened into rain
  float temp; // celsius
  PGraphics image;
  
  gravityVector[][] gravityMap;
  tile[][] tileMap;
 
  environment() {
    environWidth = worldWidth / cellWidth;
    environHeight = worldHeight / cellHeight;   
    environAltitude = (int)random(255);
    temp = (int)random(-40, 50); // celcius
    println(temp);
    rockFrequency = 0;
    
    gravityMap = new gravityVector[environHeight][environWidth];
    tileMap = new tile[environHeight][environWidth];
    for (int i = 0; i < environHeight; i++) {
      for (int j = 0; j < environWidth; j++) {
        tileMap[i][j] = new tile();
        tileMap[i][j].colors = color(0, 200 + (int)random(25), 0);    // environment type        
        gravityMap[i][j] = new gravityVector();
      }
    }
    
    generateAltitudeMap();
    //generateWaterALT((float)random(0, 70) / 100.0f);
    generateWaterALT(0.35f); // Just works out better this way
    generateRockyALT(0.60f);
    spawnRocks();
    tempInfluence();
    makeImage();
    
    int chance = initializeRain();
    if(chance == 1) {
      isRaining = false;
      waitRainOff = minute();
    } else {
      isRaining = true;
      waitRainOn = minute();
    }
    // makeImageFood();
    // updateEnviron();
  }
  
  
  // Generates altitude for each tile using the built in perlin noise generator "noise()".
  void generateAltitudeMap() {
    addPerlinNoise(6.0f);
    perturb(32.0f, 32.0f);
    erode(8.0f);
    smoothen();
  }
  
  void addPerlinNoise(float freq) {
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        tileMap[i][j].setAlt(tileMap[i][j].getAlt() + noise(freq * i / (float)environWidth, freq * j / (float)environHeight, 0));  
      }
    } 
  }
  
  // Modify generated noise to better match peaks of hills rather than spikes of mountains (makes it look more natural)
  void perturb(float freq, float maxDist) {
    int u, v;
    u = 0;
    v = 0;
    float[][] temp = new float[environWidth][environHeight];
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        u = i + (int)(noise(freq * i / (float)environWidth, freq * j / (float)environHeight, 0) * maxDist);
        v = j + (int)(noise(freq * i / (float)environWidth, freq * j / (float)environHeight, 1) * maxDist);
        if(u < 0) { u = 0; }
        if(u >= environWidth) u = environWidth - 1;
        if(v < 0) { v = 0; }
        if(v >= environWidth) v = environWidth - 1;
        temp[i][j] = tileMap[i][j].getAlt();
      }
    }
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        tileMap[u][v].setAlt(temp[i][j]);
      }
    }
  }
    
  // Smooths out a generated altitude map
  void erode(float smoothness) {
    for(int i = 1; i < environWidth - 1; i++) {
      for(int j = 1; j < environHeight - 1; j++) {
        float distMax = 0.0f;
        int[] match = { 0, 0 };
        for(int u = -1; u <= 1; u++) {
          for(int v = -1; v <= 1; v++) {
            if(Math.abs(u) + Math.abs(v) > 0) {
              float distI = tileMap[i][j].getAlt() - tileMap[i + u][j + v].getAlt();
              if(distI > distMax) {
                distMax = distI;
                match[0] = u; match[1] = v;
              }
            }
          } 
        }
        if(0 < distMax && distMax <= (smoothness / (float)environWidth)) {
          float distH = 0.5f * distMax;
          tileMap[i][j].setAlt(tileMap[i][j].getAlt() - distMax);
          tileMap[i + match[0]][j + match[1]].setAlt(tileMap[i + match[0]][j + match[1]].getAlt() + distH);
        }
      }
    }
  }
  
  void smoothen() {
    for(int i = 1; i < environWidth - 1; ++i) {
      for(int j = 1; j < environHeight - 1; ++j) {
        float total = 0.0f;
        for(int u = -1; u <= 1; u++) {
          for(int v = -1; v <= 1; v++) {
            total += tileMap[i + u][j + v].getAlt();
          }
        }
        tileMap[i][j].setAlt(total / 9.0f);
      }
    } 
  }
  
  // Simulates gravity by generating force vectors based on a tile's altidue and surrounding gravity.
  void generateGravityVectors() {
    
  }
  
  // Generate water for every tile below the altitude alt
  void generateWaterALT(float alt) {
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        if(tileMap[i][j].getAlt() <= alt) {
          tileMap[i][j].isLiquid(true);
          tileMap[i][j].setViscosity(255);
          tileMap[i][j].colors = color(20, 50, 200, (int)((abs((tileMap[i][j].getAlt()) - 1) + 0.2) * 255));
          tileMap[i][j].opacity = (int)((abs((tileMap[i][j].getAlt()) - 1) + 0.2) * 255);
        }
      }
    }
  }
  
  // Generate rocky land bodies based on altitude
  // NOTE: To let liquid and rock types combine maybe generate a second noise map and use it's "fake" altitude instead. 
  //      That or generate it similar to gravity where the steepness of a slope determines how rocky it is. 
  void generateRockyALT(float alt) {
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        if(tileMap[i][j].getAlt() >= alt) {
          tileMap[i][j].isLiquid(false);
          tileMap[i][j].setViscosity(0);
          tileMap[i][j].colors = color(170, 190, 215, (int)((abs((tileMap[i][j].getAlt()) - 0.9) * 255)));
          tileMap[i][j].opacity = (int)((abs((tileMap[i][j].getAlt()) - 1) + 0.2) * 255);
        }
      }
    }
  }
  
  // Spawn rocks with respect to rocky terrian (color); spawn more on rock terrain
  void spawnRocks() {
    for(int i = 0; i < environWidth; i++) {
      for(int j = 0; j < environHeight; j++) {
        if(tileMap[i][j].getViscosity() == 0) {
          int x = (i * cellWidth) - (worldWidth / 2);
          int y = (j * cellHeight) - (worldHeight / 2);
          int f = (int)random(100);
          if(f <= rockFrequency) {
            rock r = new rock(y, x, (int)random(10, 30));
            rocks.add(r);
          }
        }
      } 
    }
  }

  void generateWater(int numWaterBodies, int initialSize, int deltaSize) {
    int totalSize = 0;
    int x = 0;
    int y = 0;
    for(int i = 0; i < numWaterBodies; i++) {
      // water body origin
      x = (int)random(environWidth);
      y = (int)random(environHeight);
      
      totalSize = initialSize + (int)(random(deltaSize) * random(-1, 1)); // noted extra chance of delta being 0
      
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
  
  void tempInfluence() {
    int r = 0;
    int b = 0;
    int g = 0;
    color c;
    for(int i = 0; i < environHeight; i++) {
      for(int j = 0; j < environWidth; j++) {
        c = tileMap[i][j].colors;
        r = (c >> 16) & 255;
        b = (c >> 8) & 255;
        g = (c) & 255;
        //tileMap[i][j].colors = new color(r, b, g, 1); 
        // change values here and reconstruct color 
      }
    }
    println("red: " + r + " blue: " + b + " green: " + g);
  }
  
  void place_creature(creature cd, float x, float y) {
    x = (int)((worldWidth*0.5+x-1)/cellWidth);
    y = (int)((worldHeight*0.5+y-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case creature was temporarily bumped out of bounds
    y = (y+environHeight)%environHeight;
    tileMap[(int)x][(int)y].hasCreature(cd);
  }
  
  void update_scent() {
    if(!paused){
    int range = 1, tempx, tempy;
    float count;
    float[][] temparray;
    temparray = new float[environWidth][environHeight];
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if (tileMap[x][y].hasFood()) {
          count = tileMap[x][y].getScent() + 10; // food causes scent to increase
          tileMap[x][y].setScent(min(count,maxscent)); // increase scent up to the max
          tileMap[x][y].hasScent = true;
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
        tileMap[x][y].hasScent = true;
      }
    }
    }
  }

  void update_creature_scent() {
    if(!paused){
    int range = 1, tempx, tempy;
    float count = 0;
    float[][] temparray;
    int col = 0;
    int str;
    temparray = new float[environWidth][environHeight];
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if (tileMap[x][y].hasCreature != null) {
          if ( tileMap[x][y].hasCreature.getScent() == true ) {
 
            str = tileMap[x][y].hasCreature.getScentStrength();
            if( tileMap[x][y].hasCreature.getScentType() == 1 ) {
              count = tileMap[x][y].getCreatureScent() + 10; // creature causes scent to increase
              tileMap[x][y].setCreatureScent(maxscent); // increase scent up to the m
              tileMap[x][y].hasCreatureScent = true;
              for( int i = 0 - str; i <= str; i++ ) {
                for( int j = 0 - str; j <= str; j++ ) {
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].hasCreatureScent = true;
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].setCreatureScent(maxscent/str);
                }
              }
            } else if( tileMap[x][y].hasCreature.getScentType() == 2 ) {
              count = tileMap[x][y].getReproScent() + 10; // creature causes scent to increase
              tileMap[x][y].setReproScent(maxscent); // increase scent up to the max  
              tileMap[x][y].hasReproScent = true;
                for( int i = 0 - str; i <= str; i++ ) {
                for( int j = 0 - str; j <= str; j++ ) {
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].hasReproScent = true;
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].setReproScent(maxscent/str);                  
                }
              }
            } else if( tileMap[x][y].hasCreature.getScentType() == 3 ) {
              count = tileMap[x][y].getPainScent() + 10; // creature causes scent to increase
              tileMap[x][y].setPainScent(maxscent); // increase scent up to the max
              tileMap[x][y].hasPainScent = true;
              for( int i = 0 - str; i <= str; i++ ) {
                for( int j = 0 - str; j <= str; j++ ) {
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].hasPainScent = true;
                  tileMap[(x+i+environWidth)%environWidth][(y+j+environHeight)%environHeight].setPainScent(maxscent/str);
                }
              }              
            }
          }
        }
        else {

          if( tileMap[x][y].hasCreatureScent ) {
            tileMap[x][y].setCreatureScent(tileMap[x][y].getCreatureScent() * .98 );
          } else if( tileMap[x][y].hasReproScent ) {
            tileMap[x][y].setReproScent(tileMap[x][y].getReproScent() * .98 );
          } else if( tileMap[x][y].hasPainScent ) {
            tileMap[x][y].setPainScent(tileMap[x][y].getPainScent() * .98 );
          }
          /*
          count = 0;
          for (int rx = -1*range; rx < range+1; rx++) {
            for (int ry = -1*range; ry < range+1; ry++) {
              tempx = x+rx;
              tempy = y+ry;
              tempx = max(min(environWidth-1, tempx), 0);
              tempy = max(min(environHeight-1, tempy), 0);
              count += tileMap[tempx][tempy].getCreatureScent();
            }
          }
          count /= 9.0; // scent is average contribution of 9 cells
          //scent[x][y] = count;
        }
        count *= 0.98; // scent decays over time
        temparray[x][y] = count;
      }
    }
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        //scent[x][y] = min(maxscent,temparray[x][y]);
        tileMap[x][y].setCreatureScent(temparray[x][y]);
      }
          */
        }
      }
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
      p = r.getPos();
      x = (int)((worldWidth*0.5+p.x-1)/cellWidth);
      y = (int)((worldHeight*0.5+p.y-1)/cellHeight);
      x = (x+environWidth)%environWidth; // in case creature was temporarily bumped out of bounds
      y = (y+environHeight)%environHeight;
      tileMap[x][y].hasRock(true);
    }
    
    for (food fd: foods) {
      p = fd.getPos();
      if (fd != null && p != null) {
        x = (int)((worldWidth*0.5+p.x-1)/cellWidth);
        y = (int)((worldHeight*0.5+p.y-1)/cellHeight);
        x = (x+environWidth)%environWidth; // in case ccreature was temporarily bumped out of bounds
        y = (y+environHeight)%environHeight;
        tileMap[x][y].hasFood(true);
      }
    }
    update_scent();
    update_creature_scent();
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

    float getCScent(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    tileMap[x][y].DEBUG_sensing(true); // so sensed squares can be drawn for debugging purposes
    return tileMap[x][y].getCreatureScent();
  }

    float getRScent(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    tileMap[x][y].DEBUG_sensing(true); // so sensed squares can be drawn for debugging purposes
    return tileMap[x][y].getReproScent();
  }

    float getPScent(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    tileMap[x][y].DEBUG_sensing(true); // so sensed squares can be drawn for debugging purposes
    return tileMap[x][y].getPainScent();
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
  
  int checkForLiquid(double x1, double y1) {
    int x, y;
    x = (int)((worldWidth*0.5+x1-1)/cellWidth);
    y = (int)((worldHeight*0.5+y1-1)/cellHeight);
    x = (x+environWidth)%environWidth; // in case sensing point is out of bounds
    y = (y+environHeight)%environHeight;
    if (tileMap[x][y].isLiquid()) {
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
    if (displayScent) {
      //     display_scent();
      display_creature_scent();
    }
    //display_water();


    // checks to see if it can rain or not
    if(timesteps == 0)
      timeStepTemp = 0;
    updateWaterReserve();
    if(!isRaining)
      chanceOfRain();  
      
    if(isRaining) {
      rainfall();
      whileRaining();
    }
    timeStepTemp = timesteps;
  }
  
  // Commented out; water was added to the image_draw function
  /*void display_water() {
    float size = cellWidth;
    float offset = 0;
    pushMatrix();
    translate(worldWidth * -0.5, worldHeight * -0.5, -1);
    noStroke();
    
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if(tileMap[x][y].isLiquid()) {
          fill(20, 50, 200, (int)((abs((tileMap[x][y].getAlt()) - 1) + 0.2) * 255));
          rect(offset, offset, size, size);
        }
        translate(cellWidth, 0);
      }  
      translate(worldWidth*-1, cellHeight);  
    }
    popMatrix();  
  }*/
  
  void display_scent() {
    float size = cellWidth;
    float offset = 0;// cellWidth*0.5;
    pushMatrix();
    translate(worldWidth*-0.5, worldHeight*-0.5, -1);
    noStroke();
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {
        if( tileMap[x][y].hasScent ) {
          fill(225, 165, 0, 255 * tileMap[x][y].getScent() / maxscent);
          if( tileMap[x][y].getScent() < 60 ) tileMap[x][y].hasScent = false;
        } else {
          noFill();
          noStroke();
        }
        rect(offset, offset, size, size);
        translate(cellWidth, 0);
      }
      translate(worldWidth*-1, cellHeight);
    }    
    popMatrix();  
  }

  void display_creature_scent() {
    float size = cellWidth;
    float offset = 0;// cellWidth*0.5;
    pushMatrix();
    translate(worldWidth*-0.5, worldHeight*-0.5, -1);
    noStroke();
    for (int y = 0; y < environHeight; y++) {
      for (int x = 0; x < environWidth; x++) {

        if( tileMap[x][y].hasCreatureScent ) {
          fill(255, 0, 0, 255 * tileMap[x][y].getCreatureScent() / maxscent);
          if( tileMap[x][y].getCreatureScent() < 60 ) tileMap[x][y].hasCreatureScent = false;          
        } else if( tileMap[x][y].hasReproScent ) {
            fill(242, 2, 232, 255 * tileMap[x][y].getCreatureScent() / maxscent);
          if( tileMap[x][y].getCreatureScent() < 60 ) tileMap[x][y].hasReproScent = false;                      
        }
        else if( tileMap[x][y].hasPainScent ) {
            fill(50, 2, 100, 255 * tileMap[x][y].getCreatureScent() / maxscent);
          if( tileMap[x][y].getCreatureScent() < 60 ) tileMap[x][y].hasPainScent = false;                      
        } else {
          noFill();
          noStroke();
        }
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
        image.fill(tileMap[i][j].colors);
        image.rect(j*cellWidth, i*cellHeight, cellWidth, cellHeight);
      }
    }
    image.endDraw();
  }

  /**** WEATHER ****/
  
  // updates the amount of water in the water reserve
  void updateWaterReserve() {
    if(isRaining) {
      if(waterReserve <= 0) {}
      else
        waterReserve = (waterReserve - (timesteps - timeStepTemp));
    }
    if(!isRaining) {
      if(waterReserve >= waterReserveMax) {}
      else 
        waterReserve = (waterReserve + (timesteps - timeStepTemp));
    }
  }
  
  // checks to see if it can rain
  void chanceOfRain() {
    int chance = int(waterReserve / 100);
    int rand = int(random(0,100));
    tempWaitOff = minute();
    if(tempWaitOff >= waitRainOff+1 && rand <= chance) 
      isRaining = true;
    if(isRaining == true)
      waitRainOn = minute();
  }
  
  // checks water reserve amounts and lightning
  void whileRaining() {
    int chance = int(waterReserve / 100);
    int rand = int(random(0,100));
    tempWaitOn = minute();
    if(tempWaitOn >= waitRainOn+1 && (chance - rand) <= 0)
      isRaining = false;
    chanceOfLightning();
    if(isRaining == false) 
      waitRainOff = minute(); 
  }   
  
  // Randomly decides if lightning should strike
  void chanceOfLightning() {
    int chance = int(random(1,30));
    if (chance == 1) {
      lightning();
    }
  }
  
  // Draws rain animation
  void rainfall() {
    float x, y;
    fill(0, 0, 255, 50);
    rect((-worldWidth), (-worldHeight), (worldWidth*2), (worldHeight*2));
    for(int i = 0; i < 600; i++) {
      x = random(-worldWidth, worldWidth);
      y = random(-worldHeight, worldHeight);
      stroke(0, 0, 200, 95);
      line(x, y, x, y+30);
    }
  }
  
  // Draws lightning and kills a creature if it is on the tile
  void lightning() {
    int randX = int(random(-worldWidth, worldWidth));
    int randY = int(random(-worldHeight, worldHeight));
    
    int xOffset = randX;
    int yOffset = -worldHeight;
    int yFinal = randY; 
    
    noFill();
    strokeWeight(5);
    stroke(255, 255, 200);

    beginShape();
    curveVertex(xOffset, yOffset);
    curveVertex(xOffset, yOffset);
    yOffset += (int(random(50,200)));
    for(int i = 0; i < 100; i++) {
      curveVertex(xOffset+(int(random(2,15))), yOffset);
      yOffset += (int(random(50,200)));
      if(yOffset > yFinal)
        break;
      curveVertex(xOffset-(int(random(2,15))), yOffset);
    }
    curveVertex(xOffset, yFinal);
    curveVertex(xOffset, yFinal);
    endShape();

    int tileX = ((randX + (worldWidth)) / 40);
    int tileY = ((randY + (worldHeight)) / 40);

    if(tileMap[tileX][tileY].hasCreature() != null) {
      creature c = tileMap[tileX][tileY].hasCreature();
      c.changeHealth(-1000);
    }
    strokeWeight(1);
    //thunder.rewind();
    //thunder.play();  
  }
}

