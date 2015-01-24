class genome {
  float[] the_genome;
 
  int numsegments = 8;      // number of segments/ribs/spines in a creature
  
  // These are where each section of the genome starts
  int segmentsStart = 0;    // begining of genome for the segment lengths
  int colorStart = 100;     // begining of genome for the overall color
  int reproduceStart = 200; // begining of genome for the parameters for reporduction
  int physicalStart = 300;  // begining of genome for the physical characteristics, density, restitution, etc.
  int sensingStart = 400;   // begining of genome for the type, number, location of sensors
  int behaviorStart = 500;  // begining of genome for the parameters controlling behavior
  int totalgenes = 599;     // current length of the genome

  
  // "Constructor" function - this is the function to create a new genome.
  // It is called automatically when a new genome is created with the command: genome g = new genome();
  genome() {  
    the_genome = new float[totalgenes];   // create a new array (list) of values
    for (int i = 0; i < totalgenes; i++) {
      the_genome[i] = randomGaussian()*0.05;   // give each loci a random value near zero
    }
  }
  
  // Copies one genome (the source) into another, the first step in reporduction, usually followed by mutating the copy
  void copy(genome source) {
    the_genome = new float[totalgenes];
    for (int i = 0; i < totalgenes; i++) {
      the_genome[i] = source.the_genome[i];
    }
  }

  // Returns the amount of turning force (just a decimal number) the creature has evolved to apply when it senses either
  // food, another creature, a rock, or a (food) scent.
  // Notice that the argument i passed to the function determine where in the genome to get the value from: behaviorStart+i
  double getBehavior(int i) {  
    // 0 = food, 1 = creature, 2 = rock, 3 = scent
    double b;
    b = getTurningForce()*the_genome[behaviorStart+i]; // there's a turning force
    return b;
  }
  
  color getcolor() {
    //   int offset = numsegments*numsegmentgenes;   // 0 to 255
    // sigmoid mapping to 0 to 255 centered on 126
    int r = 126 + (int)(126*(the_genome[colorStart]/(1+abs(the_genome[colorStart]))));
    int g = 126 + (int)(126*(the_genome[colorStart+1]/(1+abs(the_genome[colorStart+1]))));
    int b = 126 + (int)(126*(the_genome[colorStart+2]/(1+abs(the_genome[colorStart+2]))));
    color c = color(r, g, b);
    return c;
  }
  
  int getreproduceEnergy() {
    //int offset = numsegments*numsegmentgenes+numcolorgenes;
    int e = (int)(2000*(the_genome[reproduceStart]/(1+abs(the_genome[reproduceStart]))));
    return((int)(200 + 2000+ e));   // 2 to 4200 sigmoid, 200 is the amount of energy per food
  }
  
  float getDensity() {
    //int offset = numsegments*numsegmentgenes+numcolorgenes+numdividegenes;
    float d = 1;
    if (the_genome[physicalStart] < 0) {
      d = 10 * (1/1+abs(the_genome[physicalStart]));
    }
    if (the_genome[physicalStart] >= 0) {
      d = 10 + sqrt(the_genome[physicalStart]);
    }
    
    return d; // limit 0 to infinity 
  }
  
  int getForce() {
    return((int)(500+10*the_genome[physicalStart+1])); // -infinity to infinity linear
  }
  
  int getTurningForce() {
    return((int)(100+10*the_genome[physicalStart+2])); // -infinity to infinity linear
  }
  
  
  float getRestitution() {
    //    int offset = numsegments*numsegmentgenes+numcolorgenes+numdividegenes+numDensityGenes+ numForceGenes;
    float r = 0;
    r = 0.5 + (0.5 * (the_genome[physicalStart+2]/(1+abs(the_genome[physicalStart+2]))));
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
  
  Vec2 getpoint(int i) {
    Vec2 a = new Vec2();
    int lengthbase = 20;
    float l;
    if (the_genome[i*2] < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(the_genome[i*2])));
    }
    else {
      l = lengthbase + (2*lengthbase*(the_genome[i*2]/(1+the_genome[i*2])));;
    }
    a.x = (float)(l * Math.sin((i)*PI/(numsegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numsegments)) );
    return a;
  }
  
  Vec2 getflippedpoint(int i) {
    Vec2 a = new Vec2();
    int lengthbase = 20;
    float l;
    if (the_genome[i*2] < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(the_genome[i*2])));
    }
    else {
      l = lengthbase + (2*lengthbase*(the_genome[i*2]/(1+the_genome[i*2])));
    }
    a.x = (float)(-1 * l * Math.sin((i)*PI/(numsegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numsegments)) );
    return a;
  }
  
  void mutate() {
    for (int i = 0; i < totalgenes; i++) {
      the_genome[i] += randomGaussian()*0.3;
    }
  }
}
