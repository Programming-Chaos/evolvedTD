  
// represents a trait with a number of genes, range, and index in genome
class trait {
  int genes; // number of genes for this trait
  int index; // managed index within genome array

  // TODO: implement custom ranges
  float beg = -Float.MIN_VALUE; // beginning of range
  float end = -Float.MAX_VALUE; // end of range

  // constructor for custom number of genes
  trait() { genes = 10; }
  trait(int genes) { this.genes = genes; }
}

class genome {
  ArrayList<Float> the_genome;

  int numsegments = 8; // number of segments/ribs/spines in a creature

  HashMap<String, trait> traits = new HashMap<String, trait>() {{
      // RGB color values
      put("red", new trait(1));
      put("green", new trait(1));
      put("blue", new trait(1));
      // reproduction
      put("compatibility", new trait());
      put("reproduction_energy", new trait());
      // energies
      put("forward_force", new trait());
      put("turning_force", new trait());
      put("restitution", new trait());
      // segments
      put("segments", new trait(numsegments * 2)); // current implementation of segments is... odd
      put("density", new trait());
      // behaviors
      put("food", new trait(1));
      put("creature", new trait(1));
      put("rock", new trait(1));
      put("scent", new trait(1));
    }};

  // "Constructor" function - this is the function to create a new genome.
  // It is called automatically when a new genome is created with the command: genome g = new genome();
  genome() {
    // for each trait, assign its index and count its genes
    int totalgenes = 0; // subsequently known as the_genome.size()
    for (trait the_trait : traits.values()) {
      the_trait.index = totalgenes;
      totalgenes += the_trait.genes;
    }
    the_genome = new ArrayList<Float>(totalgenes);
    for (int i = 0; i < totalgenes; i++) { // really, no fill method?
      the_genome.add(randomGaussian() * 0.05); // give each gene a random value near zero
    }
  }

  // "Copy" constructor
  genome(genome g) {
    traits = g.traits; // just keep the reference
    int totalgenes = g.the_genome.size();
    the_genome = new ArrayList<Float>(totalgenes);
    for (int i = 0; i < totalgenes; i++) {
      the_genome.add(i, g.the_genome.get(i));
    }
  }

  trait getTrait(String name) {
    trait the_trait = traits.get(name);
    if (the_trait == null) {
      print(String.format("This genome has no trait '%s'", name));
      exit();
    }
    return the_trait;
  }

  ArrayList<Float> getTraitList(String name) {
    trait the_trait = getTrait(name);
    ArrayList<Float> sub = new ArrayList<Float>(the_trait.genes);
    sub.addAll(the_genome.subList(the_trait.index, the_trait.index + the_trait.genes));
    return sub;
  }

  Float getTraitSum(String name) {
    Float sum = 0.;
    for (Float gene : getTraitList(name))
      sum += gene;
    return sum;
  }

  Float getTraitAvg(String name) {
    return getTraitSum(name) / getTrait(name).genes;
  }

  // Returns the amount of turning force (just a decimal number) the creature has evolved to apply when it senses either
  // food, another creature, a rock, or a (food) scent.
  double getBehavior(String item) {
    return getTurningForce() * getTraitSum(item); // there's a turning force
  }

  color getcolor() {
    //   mapping from allele value to color is a sigmoid mapping to 0 to 255 centered on 126
    int r = 126 + (int)(126*(getTraitSum("red")/(1+abs(getTraitSum("red")))));
    int g = 126 + (int)(126*(getTraitSum("green")/(1+abs(getTraitSum("green")))));
    int b = 126 + (int)(126*(getTraitSum("blue")/(1+abs(getTraitSum("blue")))));
    color c = color(r, g, b);
    return c;
  }

  // amount of energy a creature must have to reproduce, not used in the tower defense, but could be if we wanted creates to reproduce during a wave
  int getreproduceEnergy() {
    int e = (int)(2000*(getTraitSum("reproduction_energy")/(1+abs(getTraitSum("reproduction_energy")))));
    return((int)(200 + 2000+ e));   // 2 to 4200 sigmoid, 200 is the amount of energy per food
  }

  // Density of a creature for the box2D "physical" body.
  // Box2D automatically handles the mass as density times area, so that when a force is applied to a body the correct acceleration is generated.
  float getDensity() {
    float d = 1;
    // If the value is negative, density approaches zero asympototically from 10
    if (getTraitSum("density") < 0) {
      d = 10 * (1/1+abs(getTraitSum("density")));
    }
    // if the value is positive, density grows as 10 plus the square root of the evolved value
    if (getTraitSum("density") >= 0) {
      d = 10 + sqrt(getTraitSum("density"));
    }

    return d; // limit 0 to infinity
  }

  // Forward force to accelerate the creature, evolved, but (currently) doesn't change anytime durning a wave
  int getForce() {
    return((int)(500+10*getTraitSum("forward_force"))); // -infinity to infinity linear
  }

  // This is the base turning force, it is modified by getBehavior() above, depending on what type of object was sensed to start turning
  int getTurningForce() {
    return((int)(100+10*getTraitSum("turning_force"))); // -infinity to infinity linear
  }

  // How bouncy a creature is, one of the basic box2D body parameters, no idea how it evolves or if it has any value to the creatures
  float getRestitution() {
    float r = 0;
    r = 0.5 + (0.5 * (getTraitSum("restitution")/(1+abs(getTraitSum("restitution")))));
    return r;
  }

  float getWidth() { // calculate and return the width of the creature
    float maxX = 0;
    Vec2 temp;
    for (int i = 0; i < numsegments; i++) {
      temp = getpoint(i);
      if (temp.x > maxX) {
        maxX = temp.x;
      }
    }
    return 2*maxX;
  }

  float getLength() { // calculate and return the length of the creature
    float maxY = 0;
    float minY = 0;
    Vec2 temp;
    for (int i = 0; i < numsegments; i++) {
      temp = getpoint(i);
      if (temp.y > maxY) {
        maxY = temp.y;
      }
      if (temp.y < minY) {
        minY = temp.y;
      }
    }
    return (maxY - minY);
  }

  // Gets the end point of the ith segment/rib/spine used to create the creatures body
  Vec2 getpoint(int i) {
    Vec2 a = new Vec2();
    Float segment = getTraitList("segments").get(i);
    int lengthbase = 20;    
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));;
    }
    a.x = (float)(l * Math.sin((i)*PI/(numsegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numsegments)) );
    return a;
  }

  // Gets the end point of the ith segment/rib/spine on the other side of the creatures body
  Vec2 getflippedpoint(int i) {
    Vec2 a = new Vec2();
    Float segment = getTraitList("segments").get(i);
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));
    }
    a.x = (float)(-1 * l * Math.sin((i)*PI/(numsegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numsegments)) );
    return a;
  }

  // Mutates every value by a little bit. Biologically speaking a very high mutation rate to foster fast evolution
  void mutate() {
    for (Float f : the_genome) {
      f += randomGaussian()*0.3;
    }
  }
}
