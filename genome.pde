// Represents a creature's genomic data as an array of real values,
// loosely modeling Additive Quantitative Genetics.
class Genome {
  // a pair of chromosomes is the genome
  Chromosome xChromosome;
  Chromosome yChromosome;
  // standard deviation of mutation added to each gene in meiosis
  static final float MUTATION_DEVIATION = 0.3;
  static final float MUTATION_RATE = 0.05;
  // standard deviation of initial gene values
  static final float INITIAL_DEVIATION = 0.05;
  // multiplier for number of genes given to each trait (for
  // protective dead code)
  static final float GENE_MULTIPLIER = 4.0/3.0;
  // additional control trait to estimate genetic evolution
  Trait control = new Trait(10);

  // Metabolism
  Trait maxReproductiveEnergy = new Trait(10);
  Trait maxLocomotionEnergy = new Trait(10);
  Trait maxHealthEnergy = new Trait(10);
  static final int METABOLIC_WEIGHTS = metabolic_network.num_weights;
  ArrayList<Trait> metabolicNetwork = new ArrayList<Trait>(METABOLIC_WEIGHTS);

  // Reproduction
  Trait gameteCost = new Trait(10);
  Trait gameteTime = new Trait(10);
  Trait gameteChance = new Trait(10);
  Trait gameteEnergy = new Trait(10);

  // Weights for the brain's artificial neural network
  static final int BRAIN_INPUTS = 10;
  static final int BRAIN_OUTPUTS = 100;
  ArrayList<Trait> brain = new ArrayList<Trait>(BRAIN_INPUTS);

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
  // maximum number of segments/ribs/spines that can be evolved
  static final int MAX_SEGMENTS = 20;
  // need an extra point for the leading and trailing edge (spine)
  ArrayList<Segment> segments = new ArrayList<Segment>(MAX_SEGMENTS + 1);
  // encodes number of segments actually expressed
  Trait expressedSegments = new Trait(10);

  // TODO: remove these traits when segment refactor is complete
  Trait redColor = new Trait(10);
  Trait greenColor = new Trait(10);
  Trait blueColor = new Trait(10);
  Trait density = new Trait(10);
  Trait restitution = new Trait(10);

  private int nGenes = 0;

  // Represents a trait with a number of genes/loci and its index in the genome
  class Trait {
    int genes;
    int index;
    // TODO: allow custom range with scaling

    Trait(int g) {
      // For each trait, assign its index and count its genes
      genes = g;
      index = nGenes;
      // add an extra GENE_MULTIPLIER number of genes to the end of
      // each trait for even distribution of control (dead) genes
      nGenes += round(GENE_MULTIPLIER * g);
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
      endPoint    = new Trait(10);
      redColor    = new Trait(10);
      greenColor  = new Trait(10);
      blueColor   = new Trait(10);
      armor       = new Trait(10);
      density     = new Trait(10);
      restitution = new Trait(10);
    }
  }

  {
    // initialize the metabolic weights
    for (int i = 0; i < METABOLIC_WEIGHTS; i++) {
      metabolicNetwork.add(new Trait(10));
    }

    // initialize the brain weights
    for (int i = 0; i < BRAIN_INPUTS; i++) {
      brain.add(new Trait(BRAIN_OUTPUTS));
    }

    // initialize the segments and their traits
    for (int i = 0; i < (MAX_SEGMENTS + 1); i++) {
      segments.add(new Segment());
    }
  }

  // creates two new chromosomes
  Genome() {
    xChromosome = new Chromosome(nGenes);
    yChromosome = new Chromosome(nGenes);
  }

  // assembles two chromosomes
  Genome(Chromosome x, Chromosome y) {
    xChromosome = x;
    yChromosome = y;
  }

  class Chromosome {
    FloatList genes;

    Chromosome(int n) {
      genes = new FloatList(n);
      for (int i = 0; i < n; i++) {
        // give each gene a random value near zero
        genes.append(randomGaussian() * INITIAL_DEVIATION);
      }
    }

    Chromosome(Chromosome chromosome) {
      genes = chromosome.genes.copy();
    }

    void mutate() {
      for (int i = 0; i < genes.size(); i++) {
        // mutate only a select number of random genes
        if (random(1) < MUTATION_RATE) {
          genes.add(i, randomGaussian() * MUTATION_DEVIATION);
        }
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
}
