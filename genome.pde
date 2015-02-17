// Represents a creature's genomic data as an array of real values,
// loosely modeling Additive Quantitative Genetics.
class Genome {
  FloatList genome = new FloatList(); // a nice wrapper to an array of floats
  // TODO: make diploid with a second genome

  int numGenes = 0; // subsequently known as genome.size()
  int numSegments; // an evolved number of segments/ribs/spines in a creature

  // Represents a trait with a number of genes/loci and its index in the genome
  class Trait {
    int genes;
    int index;
    // TODO: allow custom range with scaling

    Trait(int genes) {
      // For each trait, assign its index and count its genes
      this.genes = genes;
      this.index = numGenes;
      numGenes += genes;
      for (int c = index; c < numGenes; c++) {
        // give each gene a random value near zero
        genome.append(randomGaussian() * 0.05);
      }
    }

    // Returns a list of with genes number of floats
    FloatList list() {
      // and this is why we use a FloatList
      return genome.getSubset(index, genes);
    }

    // Returns the sum of the genes of a trait
    float sum() {
      return list().sum();
    }

    // Returns the average of the genes of a trait
    float avg() {
      return sum()/genes;
    }

  }

  // Since these are not static there's a tad bit of overhead, but the
  // convenience is worth the price; adding a trait takes one LOC
  Trait numberOfSegments = new Trait(10);
  Trait redColor = new Trait(10);
  Trait greenColor = new Trait(10);
  Trait blueColor = new Trait(10);
  Trait compatibility = new Trait(10);
  Trait reproductionEnergy = new Trait(10);
  Trait forwardForce = new Trait(10);
  Trait turningForce = new Trait(10);
  Trait restitution = new Trait(10);
  Trait segments;
  Trait density = new Trait(10);
  Trait[] armor;
  Trait food = new Trait(10);
  Trait creature = new Trait(10);
  Trait rock = new Trait(10);
  Trait scent = new Trait(10);
  Trait control = new Trait(10);
  // TODO: add gender, mutation rate, etc.

  // Constructor: creates a random genome with values near zero
  Genome() {
    numSegments = getNumSegments();
    // dynamic traits must be instantiated here
    armor = new Trait[numSegments]; 
    for (int c = 0; c < numSegments; c++)
      armor[c] = new Trait(10);
    // segments need an extra for the leading and trailing edge (spine)
    segments = new Trait(numSegments + 1);
  }

  // Copy constructor: copies prior genome
  Genome(Genome g) {
    genome = g.genome.copy();
    numSegments = getNumSegments();
    armor = new Trait[numSegments];//the traits that are dependent on how many segments there are must be declared here
    for (int c = 0; c < numSegments; c++)armor[c] = new Trait(10);
    segments = new Trait(numSegments + 1);// segments need an extra for the leading and trailing edge (spine)
  }

  // Returns the amount of turning force (just a decimal number) the
  // creature has evolved to apply when it senses either food, another
  // creature, a rock, or a (food) scent.
  double getBehavior(Trait trait) {
    return getTurningForce() * trait.sum(); // there's a turning force
  }
  
  double getBehavior(int traitN) {
    if(traitN == 0){
      return getBehavior(food);
    }
    if(traitN == 1){
      return getBehavior(creature);
    }
    if(traitN == 2){
      return getBehavior(rock);
    }
    return getBehavior(scent); // there's a turning force
  }

  // Mapping from allele value to color is a sigmoid mapping to 0 to
  // 255 centered on 126
  color getColor() {
    int r = 126 + (int)(126*(redColor.sum()/(1+abs(redColor.sum()))));
    int g = 126 + (int)(126*(greenColor.sum()/(1+abs(greenColor.sum()))));
    int b = 126 + (int)(126*(blueColor.sum()/(1+abs(blueColor.sum()))));
    color c = color(r, g, b);
    return c;
  }

  // Amount of energy a creature must have to reproduce, not used in
  // the tower defense, but could be if we wanted creates to reproduce
  // during a wave.

  // TODO: use this function
  int getReproductionEnergy() {
    int e = (int)(2000*(reproductionEnergy.sum())/(1+abs(reproductionEnergy.sum())));
    return((int)(200 + 2000+ e)); // 2 to 4200 sigmoid, 200 is the amount of energy per food
  }

  // Density of a creature for the box2D "physical" body.

  // Box2D automatically handles the mass as density times area, so
  // that when a force is applied to a body the correct acceleration
  // is generated.
  float getDensity() {
    // if the value is negative, density approaches zero asympototically from 10
    if (density.sum() < 0) return (10 * (1/1+abs(density.sum())));
    // otherwise, the value is positive and density grows as 10 plus the square
    // root of the evolved value
    return (10 + sqrt(density.sum())); // limit 0 to infinity 
  }
  
  int getNumSegments() {// can be from 2 to infinity
    int ret = round(numberOfSegments.avg()+8);
    if (ret < 2) return 2;
    return ret;
  }
  
  float getArmor(int index) {
    // the value mins at 0.1
    float a = armor[index].avg();
    if ((1+a) < 0.1)return (0.1);
    return (1+a);//limit 0.1 to infinity, starts around 1
  }

  // Forward force to accelerate the creature, evolved, but
  // (currently) doesn't change anytime durning a wave
  int getForce() {
    return((int)(500+10*forwardForce.sum())); // -infinity to infinity linear
  }

  // This is the base turning force, it is modified by getBehavior()
  // above, depending on what type of object was sensed to start
  // turning
  int getTurningForce() {
    return((int)(100+10*turningForce.sum())); // -infinity to infinity linear
  }

  // How bouncy a creature is, one of the basic box2D body parameters,
  // no idea how it evolves or if it has any value to the creatures
  float getRestitution() {
    float r = 0;
    r = 0.5 + (0.5 * (restitution.sum()/(1+abs(restitution.sum()))));
    return r;
  }

  // Calculate and return the width of the creature
  float getWidth() {
    float maxX = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.x > maxX) {
        maxX = temp.x;
      }
    }
    return 2*maxX;
  }

  // Calculate and return the length of the creature
  float getLength() {
    float maxY = 0;
    float minY = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.y > maxY) {
        maxY = temp.y;
      }
      if (temp.y < minY) {
        minY = temp.y;
      }
    }
    return (maxY - minY);
  }

  // Gets the end point of the ith segment/rib/spine used to create
  // the creatures body
  Vec2 getPoint(int i) {
    Vec2 a = new Vec2();
    float segment = segments.list().get(i);
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));;
    }
    a.x = (float)(l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Gets the end point of the ith segment/rib/spine on the other side
  // of the creatures body
  Vec2 getFlippedPoint(int i) {
    Vec2 a = new Vec2();
    float segment = segments.list().get(i);
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));
    }
    a.x = (float)(-1 * l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Mutates every value by a little bit. Biologically speaking a very
  // high mutation rate to foster fast evolution
  void mutate() {
    for (int i = 0; i < genome.size(); i++) {
      genome.set(i, genome.get(i) + randomGaussian()*0.3);
    }
  }
}
