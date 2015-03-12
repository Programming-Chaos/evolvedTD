// standard deviation of mutation added to each gene in meiosis
static final float MUTATION_DEVIATION = 0.3;
static final float MUTATION_RATE = 0.20;
// standard deviation of initial gene values
static final float INITIAL_DEVIATION = 0.05;
// multiplier for number of genes given to each trait
static final float GENE_MULTIPLIER = 4.0/3.0;

// additional control trait to estimate genetic evolution
Trait control = new Trait(10);

// Metabolism
Trait maxReproductiveEnergy = new Trait(10);
Trait maxLocomotionEnergy = new Trait(10);
Trait maxHealthEnergy = new Trait(10);
ArrayList<Trait> metabolicTraits = new ArrayList<Trait>(metabolic_network.num_weights);

// Reproduction
Trait gameteCost = new Trait(10);
Trait gameteTime = new Trait(10);
Trait gameteChance = new Trait(10);
Trait gameteEnergy = new Trait(10);

// Weights for the brain's artificial neural network
static final int BRAIN_INPUTS = 10;
static final int BRAIN_OUTPUTS = 100;
ArrayList<Trait> brainTraits = new ArrayList<Trait>(BRAIN_INPUTS);

// Speciation
Trait compatibility = new Trait(10);
Trait reproductionEnergy = new Trait(10);

// Environment interaction
Trait forwardForce = new Trait(10);
Trait turningForce = new Trait(10);
Trait foodTrait = new Trait(10);
Trait creatureTrait = new Trait(10);
Trait rockTrait = new Trait(10);

// Body
Trait scentTrait = new Trait(10);

// maximum number of segments/ribs/spines that can be evolved
static final int MAX_SEGMENTS = 20;
// need an extra point for the leading and trailing edge (spine)
ArrayList<SegmentTraits> segmentTraits = new ArrayList<SegmentTraits>(MAX_SEGMENTS);
// encodes number of segments actually expressed
Trait expressedSegments = new Trait(10);

// maximum number of apendages that can be evolved
static final int MAX_APPENDAGES = MAX_SEGMENTS;
ArrayList<AppendageTraits> appendageTraits = new ArrayList<AppendageTraits>(MAX_APPENDAGES);

// sensory thresholds
Trait painTrait = new Trait(10);
Trait painDampeningTrait = new Trait(10);
Trait painThresholdTrait = new Trait(10);
Trait sidePressureTrait = new Trait(10);
Trait tasteTrait = new Trait(10);
Trait speedTrait = new Trait(10);
Trait angularMomentumTrait = new Trait(10);

ArrayList<Trait> colorTraits = new ArrayList<Trait>(color_network.num_weights);
// TODO: will these traits be gone with the use of a color network?
Trait redColorTrait = new Trait(10);
Trait greenColorTrait = new Trait(10);
Trait blueColorTrait = new Trait(10);
Trait alphaTrait = new Trait(10);

Trait trailingEndpoint = new Trait(10);

// TODO: remove these traits when segment refactor is complete

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
}

class SegmentTraits {
  Trait endPoint;
  Trait armor;
  Trait density;
  Trait restitution;
  Trait appendageSize;

  SegmentTraits() {
    endPoint = new Trait(10);
    armor = new Trait(10);
    density = new Trait(10);
    restitution = new Trait(10);
    appendageSize = new Trait(10);
  }
}

class AppendageTraits {
  Trait armor;
  Trait density;
  Trait restitution;
  Trait waterForce;
  Trait grassForce;
  Trait mountainForce;

  AppendageTraits() {
    armor = new Trait(10);
    density = new Trait(10);
    restitution = new Trait(10);
    waterForce = new Trait(10);
    grassForce = new Trait(10);
    mountainForce = new Trait(10);
  }
}

// "Static" initialization of trait lists
  {
    // initialize the metabolic weights
    for (int i = 0; i < metabolic_network.num_weights; i++) {
      metabolicTraits.add(new Trait(10));
    }

    // initialize the brain weights
    for (int i = 0; i < BRAIN_INPUTS; i++) {
      brainTraits.add(new Trait(BRAIN_OUTPUTS));
    }

    // initialize the segments and their traits
    for (int i = 0; i < MAX_SEGMENTS; i++) {
      segmentTraits.add(new SegmentTraits());
    }

    // initialize the appendages and their traits
    for (int i = 0; i < MAX_APPENDAGES; i++) {
      appendageTraits.add(new AppendageTraits());
    }

    // initialize the color network weights
    for (int i = 0; i < color_network.num_weights; i++) {
      colorTraits.add(new Trait(10));
    }
  }

// Represents a creature's genomic data as an array of real values,
// loosely modeling Additive Quantitative Genetics.
class Genome {
  // a pair of chromosomes is the genome
  Chromosome xChromosome;
  Chromosome yChromosome;

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

  // Returns a list of genes from the X chromosome
  FloatList listX(Trait trait) {
    return xChromosome.list(trait);
  }

  // Returns a list of genes from the Y chromosome
  FloatList listY(Trait trait) {
    return yChromosome.list(trait);
  }

  // Returns a combined list of genes from both chromosomes
  FloatList list(Trait trait) {
    FloatList l = listX(trait);
    l.append(listY(trait));
    return l;
  }

  // Returns the sum of the genes from the X chromosome
  float sumX(Trait trait) {
    return xChromosome.sum(trait);
  }

  // Returns the sum of the genes from the Y chromosome
  float sumY(Trait trait) {
    return yChromosome.sum(trait);
  }

  // Returns the sum of the genes from both chromosomes
  float sum(Trait trait) {
    return sumX(trait) + sumY(trait);
  }

  float avg(Trait trait) {
    return (xChromosome.avg(trait) + yChromosome.avg(trait)) / 2;
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

    FloatList list(Trait trait) {
      return genes.getSubset(trait.index, trait.genes);
    }

    float sum(Trait trait) {
      return list(trait).sum();
    }

    float avg(Trait trait) {
      return sum(trait) / trait.genes;
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
