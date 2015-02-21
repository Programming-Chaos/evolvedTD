/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */

int tournSize = 5;
class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 20;
  
  // Create gamete buckets for storing sectors of gametes. Use global
  // variables to find how many spaces are needed.
  private int buckets = (worldWidth/20)*(worldHeight/20);
  ArrayList<Genome>[] gametes = new ArrayList[buckets];
  {
    for (int i = 0; i < buckets; i++) {
      gametes[i] = new ArrayList<Genome>();
    }
  }

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
   
  void calculateFitnesses() {
    for (creature cd: swarm) {
      cd.calcFitness();

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
    for (creature cd: swarm) {
      if (cd.alive()) { // only place living creatures 
        p = cd.getPos();
        environ.place_creature(cd, p.x, p.y); // environ is a global, tells the environment where creatures are
      }
    }
  }
   
  int select() {
    int best, temp;
    float best_fit, temp_fit;
    creature c;
    best = (int)random(0,swarm.size());
    c = swarm.get(best);
    best_fit = c.getFitness();
    for (int i = 1; i < tournSize; i++) {
      temp = (int)random(0,swarm.size());
      c = swarm.get(temp);
      temp_fit = c.getFitness();
      if (temp_fit > best_fit) {
        best = temp;
        best_fit = temp_fit;
      }
    }
    return best;
  }
  
  /* Function: AreCompatible(int,int)
   * Looks at the compatibility loci of the parents passed in, and determines
   * whether they are reproductively compatible.  Viability is based on
   * the difference between the loci, with the probability being the normal
   * distribution value at the point where the difference is.  Visually, the
   * probability that an offspring is viable is the Y-value of the point on 
   * a normal distribution where x = difference between compat genes.  If the
   * difference is more than 2 standard deviations, then the parents are by
   * default incompatible
   *
   * @param p1: first parent
   * @param p2: second parent
   * @return: boolean true if offspring is viable, false if not
   */
  boolean AreCompatible(Genome g1, Genome g2) {
    double sDev = 5.0; // standard deviation: 5.0 ---- This determines the "speciation rate" by restricting the range of compatible values in the genome
    double mean = 0.0; // mean at the Y axis --------- Changing this will move the "most compatibility" value left or right of zero
    double x_val = Utilities.Sigmoid(g1.compatibility.sum(),50,50) - Utilities.Sigmoid(g2.compatibility.sum(),50,50); // This is the location to evaluate the probability.  The further away from the center of the curve, the less likely to be compatible.
    
    double r = Math.random();
    
    return r <= (1.0 / (sDev * sqrt((float)(2 * Math.PI))) * Math.exp(-1 * ((x_val - mean)*(x_val - mean)/(2 * sDev * sDev)))); // returns whether r is at or below the curve at the x_val point
  }
  void next_generation() { // creates the next generation
    ArrayList<creature> tempswarm = new ArrayList<creature>();
    // Add gametes to gamete bucket
    for (creature cd: swarm) {
      // Fitness proporitional selection
      for (int i = 0; i < (int)cd.fitness; i++) {
        // TODO: implement proximity
        gametes[0].add(cd.genome);
      }
    }

    calculateFitnesses();
    creature c;
    
    int parent1;  // two parents for sexual reproduction
    int parent2;
    
    for (int i = 0; i < pop_size; i++) { // Might be easier to produce 2 offspring at a time
      parent1 = select();
      parent2 = select();
      while (!AreCompatible(swarm.get(parent1).genome,swarm.get(parent2).genome)) {
        parent1 = select();
        parent2 = select();
        while (parent2 == parent1) parent2 = select(); // explicitly require two different parents
      }
      
      c = swarm.get(i);
      if (c.alive() == true){
        c.round_counter++;
        tempswarm.add(c);
      }else{
        c = new creature(swarm.get(parent1),20000.0); // make a new creature from the ith member of the old pop, starts with 5000 energy
        c.mutate(); // mutate the new creature 
        tempswarm.add(c); // add it to the temp swarm
      } 
    }
    for (int i = 0; i < pop_size; i++) { // Might be easier to produce 2 offspring at a time
        c = swarm.get(i);
        if (c.alive() != true){
          c.killBody();
        }
    }
    /*
    for (creature cd: swarm) { // explicitly remove bodies from the box2dworld
        cd.killBody();  
    }
    */
    swarm.clear(); // clear the old swarm
    for (int i = 0; i < pop_size; i++) {
      swarm.add(tempswarm.get(i)); // copy the tempswarm into the swarm
    }
    tempswarm.clear(); // clear the tempswarm
  }
}
