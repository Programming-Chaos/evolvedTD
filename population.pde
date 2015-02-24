/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */

class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 20;
  
  // create gamete hash table for storing gametes. Use global
  // variables to find how many spaces are needed.
  private int buckets = (worldWidth/20)*(worldHeight/20);
  ArrayList<Genome.Chromosome>[] gametes = new ArrayList[buckets];
  {
    for (int i = 0; i < buckets; i++) {
      gametes[i] = new ArrayList<Genome.Chromosome>();
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

  // scales fitness to O(10)
  int nGametes(float fitness) {
    return int(fitness/1000);
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
        gametes[0].addAll(c.genome.getGametes());
      }
    }

    while (generation.size() < POP_SIZE) {
      // broadcast breeding, i.e. random selection
      // TODO: refactor for proximity breeding
      Genome.Chromosome x = gametes[0].get(int(random(gametes[0].size())));
      Genome.Chromosome y = gametes[0].get(int(random(gametes[0].size())));

      generation.add(new creature(new Genome(x, y), 20000.0));
    }

    gametes[0].clear(); // TODO: replace with sexual cannibalism
    swarm = generation;
  }
}
