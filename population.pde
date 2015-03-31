/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */
import java.util.Collections;

class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 35;

  float baseGameteChance = 0.4; // Base gamete success rate
  int baseGameteRadius = 6; // Base gamete mating range

  population() {
    swarm = new ArrayList<creature>();
    float a;
    for (int i = 0; i < POP_SIZE; i++) {
      a = random(0, 2*PI);
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
    Vec2 closest = new Vec2(0,0), temp;
    float distance, tempd;
    distance = 100000000; // very large value so first living creature will be closer
    for (creature c: swarm) {
      if (c.alive) { // skip non-alive creatures
        temp = c.getPos();
        tempd = sqrt((temp.x-v.x)*(temp.x-v.x)+(temp.y-v.y)*(temp.y-v.y));
        if (tempd < distance) {
          distance = tempd;
          closest = temp;
        }
      }
    }
    return closest;
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
  boolean areGametesCompatible(Genome.Chromosome gamete1,
                               Genome.Chromosome gamete2) {
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
    // at end of wave, update data collection
    if (swarm.size() > 0) {
      updateData();
    }
    
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
    // Place gametes in order of time.
    Collections.sort(gametes, new GameteComparator());
    
    int childrenBred = 0;
    int childrenNew = 0;
    int multiplier = 0;
    int range;
    
    while (generation.size() < POP_SIZE) {
      // increase search range with each pass thru.
      range = multiplier++ * 5;
      //TODO: decrease success chance when range is increased.
      
      // add random creatures if no gametes
      if (gametes.size() < 2) {
        println("ERROR: Not enough gametes");
        break;
      }
      
      Gamete g1, g2;
      int size = gametes.size();
      // i is first gamete j is it's chosen mate
      for (int i=0; i < size - 1; i++) {
        g1 = gametes.get(i);
        for (int j = i+1; j < size; j++) {
          g2 = gametes.get(j);
          
          if (g2.xPos > g1.xPos - range && g2.xPos < range && // within x range
              g2.yPos > g1.yPos - range && g2.yPos < range) { // within y range
            // Remove gametes from list and mate
            gametes.remove(j); j--;
            gametes.remove(i); i--;
            size = gametes.size();
            
            // Gamete coordinates
            int px = (g1.xPos - (g1.xPos-g2.xPos)/2);
            int py = (g1.yPos - (g1.yPos-g2.yPos)/2);
            
            // Check coordinates for other creatures spawned in this tile.
            for (int c=0; c < generation.size(); c++) {
              Vec2 posCheck = box2d.getBodyPixelCoord(generation.get(c).body);
              int xCheck = (int)(posCheck.x / cellWidth);
              int yCheck = (int)(posCheck.y / cellHeight);
              
              // while creature already occupies tile 
              // (3 is the safety range to prevent stacking)
              while ((px <= xCheck + 3) && (px >= xCheck - 3) && 
                     (py <= yCheck + 3) && (py >= yCheck - 3)) {
                // Reset c.  Need to make it thru entire list without flagging this.
                c = -1; //c++ == 0
                // Move new creature in a random direction
                switch ((int)random(8)) {
                  case 0: //North
                    py--;
                    break;
                  case 1: //NorthEast
                    py--;
                    px++;
                    break;
                  case 2: //East
                    px++;
                    break;
                  case 3: //SouthEast
                    py++;
                    px++;
                    break;
                  case 4: //South
                    py++;
                    break;
                  case 5: //SouthWest
                    py++;
                    px--;
                    break;
                  case 6: //West
                    px--;
                    break;
                  case 7: //NorthWest
                    py--;
                    px++;
                    break;
                  default: break;
                }
                
                // Make sure position is still in bounds
                if (px >= worldWidth   / cellWidth)  px = worldWidth / cellWidth - 5;
                if (px <= 0)                         px = 5;
                if (py >= worldHeight  / cellHeight) py = worldHeight / cellHeight - 5;
                if (py <= 0)                         py = 5;
              }
            }
            Vec2 pos = new Vec2(px * cellWidth, py * cellHeight) ;
      
            childrenBred++;
            generation.add(new creature(new Genome(g1.gamete, g2.gamete),
                                        10000 + g1.energy + g2.energy, pos));
            break;
          }
        }
      }
    }
    //println("made " + childrenBred + " and needed " + childrenNew + " more");
    swarm.clear();
    swarm = generation;
    
  }
  
  void updateData() {
    
    //average variables
    float massAvg = 0, widthAvg = 0, denseAvg = 0, armorAvg = 0, 
          wingAvg = 0, wingSizeAvg = 0, antennaeAvg = 0, colorAvg = 0, 
          velAvg = 0, acclAvg = 0, hpAvg = 0;
    int count = 0;
    
    for(creature c : swarm) {
      // Update creature traits data
      TableRow c_traitsRow = c_traits.addRow();
      c_traitsRow.setInt("   Gen   "        , generation);
      c_traitsRow.setInt("   Creature ID   ", c.num);
      c_traitsRow.setFloat("   Mass   "     , c.getMass());
      c_traitsRow.setFloat("   Width   "    , c.getWidth());
      c_traitsRow.setFloat("   Density   "  , c.getDensity());
      c_traitsRow.setFloat("   Armor   "    , c.getArmor());
      //c_traitsRow.setFloat("   Wing #   ", );
      //c_traitsRow.setFloat("   Wing Size   ", );
      //c_traitsRow.setFloat("   Antennae #   ", );
      //c_traitsRow.setFloat("   Color   ", );
      c_traitsRow.setFloat("   Velocity   " , c.maxMovementSpeed);
      //c_traitsRow.setFloat("   Acceleration   ", );
      c_traitsRow.setFloat("   Max HP   "   , c.maxHealth); 
      
      // Update creature trait averages data
      massAvg  += c.getMass();
      widthAvg += c.getWidth();
      denseAvg += c.getDensity();
      armorAvg += c.getArmor();
      velAvg   += c.maxMovementSpeed;
      hpAvg    += c.maxHealth;
      
      // Update creature reproduction data
      TableRow repRow = reproduction.addRow();
      repRow.setInt("   Gen   "          , generation);
      repRow.setInt("   Creature ID   "  , c.num);
      repRow.setInt("   Spawn X   "      , (int)c.sPos.x / cellWidth);
      repRow.setInt("   Spawn Y   "      , (int)c.sPos.y / cellHeight);
      repRow.setInt("   # of Gametes   " , c.gameteStack.size());
      repRow.setFloat("   Gamete Cost   ", c.baseGameteCost + c.genome.avg(gameteCost));
      repRow.setFloat("   Gamete Time   ", c.baseGameteTime + c.genome.avg(gameteTime));
      
      // Update the creature senses data
      TableRow senseRow = sensing.addRow();
      senseRow.setInt("   Gen   "           , generation);
      senseRow.setInt("   Creature ID   "   , c.num);
      senseRow.setInt("   Creature Scent   ", c.getScentType());
      //senseRow.setInt("   Creature Taste   ", );
      
      // Update the creature metabolism data
      TableRow metabRow = metabolism.addRow();
      metabRow.setInt("   Gen   "                    , generation);
      metabRow.setInt("   Creature ID   "            , c.num);
      metabRow.setFloat("   Total Energy Space   "   , c.total_energy_space);
      metabRow.setFloat("   Total Energy Consumed   ", c.total_energy_consumed);
      metabRow.setFloat("   Locomotion Space   "     , c.max_energy_locomotion);
      metabRow.setFloat("   Locomotion Used   "      , c.locomotion_used);
      metabRow.setFloat("   Reproduction Space   "   , c.max_energy_reproduction);
      metabRow.setFloat("   Reproduction Used   "    , c.reproduction_used);
      metabRow.setFloat("   Reproduction Passed   "  , c.reproduction_passed);
      metabRow.setFloat("   Health Space   "         , c.max_energy_health);
      metabRow.setFloat("   Health Used   "          , c.health_used);
      metabRow.setFloat("   Total Energy Used   "    , c.locomotion_used + c.reproduction_used + c. health_used);
      
      // Update the creature lifetime ticks data
      TableRow ticksRow = lifetime.addRow();
      ticksRow.setInt("   Gen   "           , generation);
      ticksRow.setInt("   Creature ID   "   , c.num);
      ticksRow.setInt("   Ticks on Algae   ", c.time_on_land);
      ticksRow.setInt("   Ticks on Water   ", c.time_in_water);
      //ticksRow.setInt("   Ticks on Rock   " , );
      ticksRow.setInt("   Total Lifetime   ", c.timestep_counter);
      
      count ++;
    }
    
    // Update creature trait averages data
    TableRow c_avgsRow = c_avgs.addRow();
    c_avgsRow.setInt("   Gen   ", generation);
    c_avgsRow.setFloat("   Avg Mass   ", massAvg/count);
    c_avgsRow.setFloat("   Avg Width   ", widthAvg/count);
    c_avgsRow.setFloat("   Avg Density   ", denseAvg/count);
    c_avgsRow.setFloat("   Avg Armor   ", armorAvg/count);
    c_avgsRow.setFloat("   Avg Wing #   ", wingAvg/count);
    c_avgsRow.setFloat("   Avg Wing Size   ", wingSizeAvg/count);
    c_avgsRow.setFloat("   Avg Antennae #   ", antennaeAvg/count);
    c_avgsRow.setFloat("   Avg Color   ", colorAvg/count);
    c_avgsRow.setFloat("   Avg Velocity   ", velAvg/count);
    c_avgsRow.setFloat("   Avg Acceleration   ", acclAvg/count);
    c_avgsRow.setFloat("   Avg Max HP   ", hpAvg/count);
    
    writeTables(); 
  }
}
