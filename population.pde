/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */
import java.util.Collections;

class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 50;

  float baseGameteChance = 0.4; // Base gamete success rate
  int baseGameteRadius = 6; // Base gamete mating range

  population() {
    swarm = new ArrayList<creature>();
    float a;
    for (int i = 0; i < POP_SIZE; i++) {
      a = i*(2*PI/POP_SIZE);//random(0, 2*PI);
      creature c = new creature(0.45*worldWidth*sin(a),0.45*worldWidth*cos(a),a);
      swarm.add(c);
    }
  }

  void update() {
    for (creature c : swarm) {
      c.update();
    }
  }

  void display() {
    for (creature c : swarm) {
      c.display();
    }
  }

  Vec2 vec_to_random_creature() {
    Vec2 v = new Vec2(0,0);
    creature c;
    if (get_alive() == 0) {
      return v; // none left alive
    }
    c = swarm.get(int(random(swarm.size())));
    while(!c.alive) {
      c = swarm.get(int(random(swarm.size())));
    }
    return c.getPos();
  }

  Vec2 closest(Vec2 v) {
    Vec2 ret = new Vec2(0,0);
    float temp, minDistance = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) { // skip non-alive creatures
        if (first) {
          ret = c.getPos();
          minDistance = sqrt((ret.x-v.x)*(ret.x-v.x)+(ret.y-v.y)*(ret.y-v.y));
          first = false;
        }
        else {
          temp = sqrt((c.getPos().x-v.x)*(c.getPos().x-v.x)+(c.getPos().y-v.y)*(c.getPos().y-v.y));
          if (temp < minDistance ) {
             minDistance = temp;
             ret = c.getPos();
          }  
        }
      }
    }
    return ret;
  }
  
  Vec2 highestAlpha() {
    Vec2 ret = new Vec2(0,0);
    float temp, minAlpha = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) {
        if (first) {
          minAlpha = c.genome.sum(alphaTrait);
          ret = c.getPos();
          first = false;
        }
        else {
          temp = c.genome.sum(alphaTrait);
          if (temp < minAlpha ) {
             minAlpha = temp;
             ret = c.getPos();
          }  
        }
      }
    }
    return ret;
  }

  // returns the number of living creatures, used to decide whether to
  // end a wave
  int get_alive() {
    int counter = 0;
    for (creature c: swarm) {
      if (c.alive) {
        counter++;
      }
    }
    return counter;
  }

  void set_creatures() {
    Vec2 p = new Vec2();
    for (creature c: swarm) {
      if (c.alive) { // only place living creatures
        p = c.getPos();
        // tell the global environment where the creatures are
        environ.place_creature(c, p.x, p.y);
      }
    }
  }

  /* Computes compatibility of two gametes
   *
   * Looks at the compatibility loci of the parents passed in, and
   * determines whether they are reproductively compatible.  Viability
   * is based on the difference between the loci, with the probability
   * being the normal distribution value at the point where the
   * difference is.  Visually, the probability that an offspring is
   * viable is the Y-value of the point on a normal distribution where
   * x = difference between compat genes.  If the difference is more
   * than 2 standard deviations, then the parents are by default
   * incompatible
   */
  boolean areGametesCompatible(Chromosome gamete1, Chromosome gamete2) {
    if (gamete1 == null || gamete2 == null)
      return false;

    // standard deviation: 5.0 ---- This determines the "speciation
    // rate" by restricting the range of compatible values in the
    // genome
    double sDev = 5.0;

    // mean at the Y axis --------- Changing this // will move the
    // "most compatibility" value // left or right of zero
    double mean = 0.0;

    // This is the location to evaluate the probability.  The further
    // away from the center of the curve, the less likely to be
    // compatible.
    double x_val = Utilities.Sigmoid(gamete1.sum(compatibility), 50, 50)
      - Utilities.Sigmoid(gamete2.sum(compatibility), 50, 50);

    double r = Math.random();

    // returns whether r is at or below the curve at the x_val point
    return r <= (1.0 / (sDev * sqrt((float)(2 * Math.PI)))
                 * Math.exp(-1 * ((x_val - mean)*(x_val - mean)
                                  / (2 * sDev * sDev))));
  }

  // scales fitness to O(10)
  int nGametes(float fitness) {
    return int(fitness/1000);
  }

  // creates the next generation
  void next_generation() {
    
    ArrayList<Gamete> gametes = new ArrayList();
    ArrayList<creature> generation = new ArrayList<creature>();
    
    for (creature c : swarm) {
      // Kill the bodies of any creatures that are still alive
      if (c.alive)
        c.killBody();

      // Add all of a creatures gametes to the gamete pool
      for(Gamete g : c.gameteStack) {
        gametes.add(g);
      }
    }
    // at end of wave, update data collection
    updateData();
    // Place gametes in order of time.
//    Collections.sort(gametes, new GameteComparator());
    
    int multiplier = 0;
    int range;
    Gamete g1, g2;
    int variance = 15; // Used for variable pop size with random selection
    int size = gametes.size();
    int rand;
    ArrayList<Integer> inProximity = new ArrayList<Integer>();
    
    while (generation.size() < POP_SIZE) {
      // increase search range with each pass thru.
      range = multiplier++ * 5;
      //TODO: decrease success chance when range is increased.
      
      // print error if not enough gametes
      if (gametes.size() < 2) {
        println("ERROR: Not enough gametes");
        break;
      }
      
      // i is first gamete j is it's chosen mate
      for (int i=0; i < variance && i < size; i++) {
        rand = (int)random(size);
        g1 = gametes.get(rand); // Randomly select a gamete
        inProximity.clear();
        
        // copy array position of gametes in proximity
        for (int j=0; j < size; j++) {
          if (j == rand) {//if same gamete... skip
            j++;
          }
          if (j >= size) {//if j is beyond the list of gametes, break
            break;
          }
          
          g2 = gametes.get(j);
        
          // Check if g2 is in range of g1
          if (g2.xPos > g1.xPos - range && g2.xPos < g1.xPos + range && // within x range
              g2.yPos > g1.yPos - range && g2.yPos < g1.yPos + range) { // within y range
            inProximity.add(j);       
          }
        }
        
        // if any match has been found:
        if (inProximity.size() > 0) {
          rand = (int)random(inProximity.size());
          int listPos = inProximity.get(rand);
          g2 = gametes.get(listPos); //get random mate within range
          gametes.remove(g1); //remove first gamete
          gametes.remove(g2); //remove second gamete
          size = gametes.size(); //update list size variable
          
          // Gamete coordinates
          int px = (g1.xPos - (g1.xPos-g2.xPos)/2);
          int py = (g1.yPos - (g1.yPos-g2.yPos)/2);
          Vec2 pos = new Vec2(px, py);
          
          // Check coordinates for other creatures or rocks spawned in this tile.
          while( checkForCreature(pos, generation) || checkForRock(pos, rocks)){};
          
          pos.x *= cellWidth;
          pos.y *= cellHeight;
    
          generation.add(new creature(new Genome(g1.gamete, g2.gamete),
                                      10000 + g1.energy + g2.energy, pos));
        }
        
      }
    }
    swarm = generation;
  }
  
  Boolean checkForCreature(Vec2 pos, ArrayList<creature> list) {
    Boolean check = false;
    
    // Check all creatures in list
    for (int c=0; c < list.size(); c++) {
      Vec2 posCheck = box2d.getBodyPixelCoord(list.get(c).body);
      
      if (checkSpawnLocation(pos, posCheck)) {
        c = -1; // must make it thru whole list without needing to move.
        check = true;
      }
    }
    return check;
  }
  
  Boolean checkForRock(Vec2 pos, ArrayList<rock> list) {
    Boolean check = false;
    
    // Check all rocks in list
    for (int c=0; c < list.size(); c++) {
      Vec2 posCheck = box2d.getBodyPixelCoord(list.get(c).the_rock);
      
      if (checkSpawnLocation(pos, posCheck)) {
        c = -1; // must make it thru whole list without needing to move.
        check = true;
      }
    }
    return check;
  }
  
  Boolean checkSpawnLocation(Vec2 pos, Vec2 posCheck) {
    Boolean check = false;
    
    // Check coordinates for other collidables spawned in this tile.
    int xCheck = (int)(posCheck.x / cellWidth);
    int yCheck = (int)(posCheck.y / cellHeight);
    
    // while collidable already occupies tile 
    // (3 is the safety range to prevent stacking)
    while ((pos.x <= xCheck + 3) && (pos.x >= xCheck - 3) && 
           (pos.y <= yCheck + 3) && (pos.y >= yCheck - 3)) {
      check = true;
      
      // Move new creature in a random direction
      switch ((int)random(8)) {
        case 0: //North
          pos.y--;
          break;
        case 1: //NorthEast
          pos.y--;
          pos.x++;
          break;
        case 2: //East
          pos.x++;
          break;
        case 3: //SouthEast
          pos.y++;
          pos.x++;
          break;
        case 4: //South
          pos.y++;
          break;
        case 5: //SouthWest
          pos.y++;
          pos.x--;
          break;
        case 6: //West
          pos.x--;
          break;
        case 7: //NorthWest
          pos.y--;
          pos.x++;
          break;
        default: break;
      }
      
      // Make sure position is still in bounds
      if (pos.x >= worldWidth   / cellWidth)  pos.x = worldWidth / cellWidth - 5;
      if (pos.x <= 0)                         pos.x = 5;
      if (pos.y >= worldHeight  / cellHeight) pos.y = worldHeight / cellHeight - 5;
      if (pos.y <= 0)                         pos.y = 5;
    }

    return check;
  }
  
  void updateData() {
    
    //average variables
    float massAvg = 0, widthAvg = 0, denseAvg = 0, armorAvg = 0, 
          wingAvg = 0, wingSizeAvg = 0, avgWingSize = 0, antennaeAvg = 0, colorAvg = 0, 
          velAvg = 0, acclAvg = 0, hpAvg = 0;
    int count = 0;
    
    for(creature c : swarm) {
      // Update creature traits data
      TableRow c_traitsRow = c_traits.addRow();
      c_traitsRow.setInt("   Gen   "        , generation);
      c_traitsRow.setInt("   Creature ID   ", c.num);
      c_traitsRow.setFloat("   Mass   "     , c.getMass());
      c_traitsRow.setFloat("   Width   "    , c.getWidth());
      c_traitsRow.setFloat("   Density   "  , c.getCreatureDensity());
      c_traitsRow.setFloat("   Wing Size   ", c.getMaxWingSize());
      c_traitsRow.setFloat("   Velocity   " , c.maxMovementSpeed);
      
      // Update creature trait averages data
      massAvg  += c.getMass();
      widthAvg += c.getWidth();
      denseAvg += c.getCreatureDensity();
      armorAvg += c.getArmor();
      velAvg   += c.maxMovementSpeed;
      hpAvg    += c.maxHealth;
      avgWingSize += c.getMaxWingSize();
   
      // Update the creature metabolism data
      TableRow metabRow = metabolism.addRow();
      metabRow.setInt("   Gen   "                    , generation);
      metabRow.setInt("   Creature ID   "            , c.num);
      metabRow.setFloat("   Total Energy Space   "   , c.total_energy_space);
      metabRow.setFloat("   Total Energy Consumed   ", c.total_energy_consumed);
      metabRow.setFloat("   Total Energy Used   "    , c.locomotion_used + c.reproduction_used + c. health_used);
      
      count ++;
    }
    
    // Update creature trait averages data
    TableRow c_avgsRow = c_avgs.addRow();
    c_avgsRow.setInt("   Gen   ", generation);
    c_avgsRow.setFloat("   Avg Mass   ", massAvg/count);
    c_avgsRow.setFloat("   Avg Width   ", widthAvg/count);
    c_avgsRow.setFloat("   Avg Density   ", denseAvg/count);
    c_avgsRow.setFloat("   Avg Wing Size   ", wingSizeAvg/count);
    c_avgsRow.setFloat("   Avg Velocity   ", velAvg/count);   
    
    // Update the environment data
    fConsumed += (fStart - foods.size());
    tStrikes += rStrikes;
    tKills += rKills;
    TableRow envRow = env.addRow();
    envRow.setInt("   Gen   "                       , generation);
    envRow.setInt("   Food at Start   "             , fStart);
    envRow.setInt("   Food at End   "               , foods.size());
    envRow.setInt("   Food Consumed   "             , fStart - foods.size());
    //reset environment round variables.
    rStrikes = 0;
    rKills = 0;
    
    writeTables(); 
  }
}
