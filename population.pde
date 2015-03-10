/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */

class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 20;
  
  ArrayList<Genome.Chromosome> gametes = new ArrayList();

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

  // get random gamete from gametes pool n
  Genome.Chromosome getRandomGamete(int n) {
    return gametes.get(int(random(gametes.size())));
  }

  // creates the next generation
  void next_generation() {
    ArrayList<creature> generation = new ArrayList<creature>();

    for (creature c : swarm) {
      c.calcFitness();
      // Keep the survivors
      if (c.alive) {
        c.round_counter++;
        generation.add(c);
      }

      // Add 2 * scaled fitness number of gametes to bucket for
      // "fitness proportional selection"
      for (int i = 0; i < nGametes(c.fitness); i++) {
        // TODO: replace with an action which produces gametes in a
        // certain proximity
        gametes.addAll(c.genome.getGametes());
      }
    }

    while (generation.size() < POP_SIZE) {
      // broadcast breeding, i.e. random selection
      // TODO: refactor for proximity breeding
      Genome.Chromosome x = null;
      Genome.Chromosome y = null;

      while (!areGametesCompatible(x, y)) {
        x = getRandomGamete(0);
        y = getRandomGamete(0);
      }

      generation.add(new creature(new Genome(x, y), 20000.0));
    }

    gametes.clear(); // TODO: replace with sexual cannibalism
    swarm = generation;
  }
}
