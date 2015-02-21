// Represents a creature's genomic data as an array of real values,
// loosely modeling Additive Quantitative Genetics.
class Genome {
  class Chromosome {
    FloatList genes;

    Chromosome(int n) {
      genes = new FloatList(n);
      for (int i = 0; i < n; i++) {
        // give each gene a random value near zero
        genes.append(randomGaussian() * 0.05);
      }
    }

    Chromosome(Chromosome chromosome) {
      genes = chromosome.genes.copy();
    }

    void mutate() {
      for (int i = 0; i < genes.size(); i++) {
        genes.set(i, genes.get(i) + randomGaussian()*0.3);
      }
    }
  }

  // a pair of chromosomes is the genome
  Chromosome xChromosome;
  Chromosome yChromosome;

  int nGenes = 0; // subsequently known as genome.size()
  // maximum number of segments/ribs/spines in a creature
  static final int MAX_SEGMENTS = 20;

  // Represents a trait with a number of genes/loci and its index in the genome
  class Trait {
    int genes;
    int index;
    // TODO: allow custom range with scaling

    Trait(int genes) {
      // For each trait, assign its index and count its genes
      this.genes = genes;
      this.index = nGenes;
      nGenes += genes;
    }

    // Returns a list of with 2 * genes number of floats
    FloatList list() {
      FloatList l = xChromosome.genes.getSubset(index, genes);
      l.append(yChromosome.genes.getSubset(index, genes));
      return l;
    }

    // Returns the sum of the genes from both chromosomes for the trait
    float sum() {
      return list().sum();
    }

    // Returns the average of the genes of a trait
    float avg() {
      return sum()/(genes * 2);
    }
  }

  class Segment {
    Trait endPoint;
    Trait redColor;
    Trait greenColor;
    Trait blueColor;
    Trait armor;
    Trait density;
    Trait restitution;

    Segment() {
      endPoint = new Trait(10);
      redColor = new Trait(10);
      greenColor = new Trait(10);
      blueColor = new Trait(10);
      armor = new Trait(10);
      density = new Trait(10);
      restitution = new Trait(10);
    }
  }

  // need an extra point for the leading and trailing edge (spine)
  Segment[] segments = new Segment[MAX_SEGMENTS + 1];
  {
    // initialize the segments and their traits
    for (int i = 0; i < (MAX_SEGMENTS + 1); i++) {
      segments[i] = new Segment();
    }
  }

  // encodes number of expressed traits
  Trait expressedSegments = new Trait(10);

  // Speciation
  Trait compatibility = new Trait(10);
  Trait reproductionEnergy = new Trait(10);
  // TODO: add mutation rate

  // Environment interaction
  Trait forwardForce = new Trait(10);
  Trait turningForce = new Trait(10);
  Trait food = new Trait(10);
  Trait creature = new Trait(10);
  Trait rock = new Trait(10);

  // Body
  Trait scent = new Trait(10);
  Trait control = new Trait(10);
  // TODO: add gender

  // TODO: remove these traits when segment refactor is complete
  Trait redColor = new Trait(10);
  Trait greenColor = new Trait(10);
  Trait blueColor = new Trait(10);
  Trait armor = new Trait(10 * MAX_SEGMENTS);
  Trait density = new Trait(10);
  Trait restitution = new Trait(10);

  // Constructor: creates two new chromosomes
  Genome() {
    xChromosome = new Chromosome(nGenes);
    yChromosome = new Chromosome(nGenes);
  }

  // Copy constructor: copies prior genome
  Genome(Genome g) {
    xChromosome = new Chromosome(g.xChromosome);
    yChromosome = new Chromosome(g.yChromosome);
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
    // TODO: refactor for density per segment
    // if the value is negative, density approaches zero asympototically from 10
    if (density.sum() < 0) return (10 * (1/1+abs(density.sum())));
    // otherwise, the value is positive and density grows as 10 plus the square
    // root of the evolved value
    return (10 + sqrt(density.sum())); // limit 0 to infinity
  }

  float getArmor(int index) {
    // TODO: refactor for armor per segment
    // the value mins at 0.1
    float a = armor.avg();
    if ((1+a) < 0.1)
      return (0.1);
    return (1+a);//limit 0.1 to infinity, starts around 1
  }

  // Forward force to accelerate the creature, evolved, but
  // (currently) doesn't change anytime durning a wave
  int getForce() {
    // TODO: Move this to creature
    return((int)(500+10*forwardForce.sum())); // -infinity to infinity linear
  }

  // How bouncy a creature is, one of the basic box2D body parameters,
  // no idea how it evolves or if it has any value to the creatures
  float getRestitution() {
    // TODO: refactor for restitution per segment
    float r = 0;
    r = 0.5 + (0.5 * (restitution.sum()/(1+abs(restitution.sum()))));
    return r;
  }

  // Mutates every value by a little bit. Biologically speaking a very
  // high mutation rate to foster fast evolution.
  void mutate() {
    // TODO: refactor this into meiosis
    xChromosome.mutate();
    yChromosome.mutate();
  }
}
