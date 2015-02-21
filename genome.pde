// Represents a creature's genomic data as an array of real values,
// loosely modeling Additive Quantitative Genetics.
class Genome {
  // a pair of chromosomes is the genome
  Chromosome xChromosome;
  Chromosome yChromosome;
  // standard deviation of float added to each gene in meiosis
  static final float MUTATION_RATE = 0.3;

  // Speciation
  Trait compatibility = new Trait(10);
  Trait reproductionEnergy = new Trait(10);

  // Environment interaction
  Trait forwardForce = new Trait(10);
  Trait turningForce = new Trait(10);
  Trait food = new Trait(10);
  Trait creature = new Trait(10);
  Trait rock = new Trait(10);

  // Body
  // TODO: add gender
  Trait scent = new Trait(10);
  Trait control = new Trait(10);
  Segment[] segments;
  // encodes number of segments actually expressed
  Trait expressedSegments = new Trait(10);
  // maximum number of segments/ribs/spines that can be evolved
  static final int MAX_SEGMENTS = 20;

  // TODO: remove these traits when segment refactor is complete
  Trait redColor = new Trait(10);
  Trait greenColor = new Trait(10);
  Trait blueColor = new Trait(10);
  Trait density = new Trait(10);
  Trait restitution = new Trait(10);

  private int nGenes = 0;

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
        genes.set(i, genes.get(i) + randomGaussian() * MUTATION_RATE);
      }
    }
  }

  ArrayList getGametes() {
    ArrayList<Chromosome> gametes = new ArrayList<Chromosome>(2);

    // recombine
    Chromosome x = new Chromosome(nGenes);
    Chromosome y = new Chromosome(nGenes);

    int start = int(random(nGenes));
    int num = int(random(nGenes - start));

    // TODO: fix this naive approach to allow for circular swap

    // get first section from own chromosome
    x.genes.append(xChromosome.genes.getSubset(0, start));
    y.genes.append(yChromosome.genes.getSubset(0, start));

    // get swapped section
    x.genes.append(yChromosome.genes.getSubset(start, num));
    y.genes.append(xChromosome.genes.getSubset(start, num));

    // get last section from own chromosome
    x.genes.append(xChromosome.genes.getSubset(start + num, nGenes - start - num));
    y.genes.append(yChromosome.genes.getSubset(start + num, nGenes - start - num));

    gametes.add(x);
    gametes.add(y);

    // mutate
    for (Chromosome chromosome : gametes)
      chromosome.mutate();
    return gametes;
  }

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

  {
    // need an extra point for the leading and trailing edge (spine)
    segments = new Segment[MAX_SEGMENTS + 1];
    // initialize the segments and their traits
    for (int i = 0; i < (MAX_SEGMENTS + 1); i++) {
      segments[i] = new Segment();
    }
  }

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

  // Mutates every value by a little bit. Biologically speaking a very
  // high mutation rate to foster fast evolution.
  void mutate() {
    // TODO: refactor this into meiosis
    xChromosome.mutate();
    yChromosome.mutate();
  }
}
