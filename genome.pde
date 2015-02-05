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
    //   mapping from allele value to color is a sigmoid mapping to 0 to 255 centered on 126
    int r = 126 + (int)(126*(the_genome[colorStart]/(1+abs(the_genome[colorStart]))));
    int g = 126 + (int)(126*(the_genome[colorStart+1]/(1+abs(the_genome[colorStart+1]))));
    int b = 126 + (int)(126*(the_genome[colorStart+2]/(1+abs(the_genome[colorStart+2]))));
    color c = color(r, g, b);
    return c;
  }
  
  // amount of energy a creature must have to reproduce, not used in the tower defense, but could be if we wanted creates to reproduce during a wave
  int getreproduceEnergy() {
    int e = (int)(2000*(the_genome[reproduceStart]/(1+abs(the_genome[reproduceStart]))));
    return((int)(200 + 2000+ e));   // 2 to 4200 sigmoid, 200 is the amount of energy per food
  }
  
  double getCompat() {
    double sum = 0;
    for (int i = 0; i < 10; i++) { 
      sum += the_genome[reproduceStart+1+i];
    }
    return sum;
  }
  
  // Density of a creature for the box2D "physical" body.
  // Box2D automatically handles the mass as density times area, so that when a force is applied to a body the correct acceleration is generated.
  float getDensity() {
    float d = 1;
    // If the value is negative, density approaches xzro asymtotically from 10
    if (the_genome[physicalStart] < 0) {
      d = 10 * (1/1+abs(the_genome[physicalStart]));
    }
    // if the value is positive, density grows as 10 plus the square root of the evolved value
    if (the_genome[physicalStart] >= 0) {
      d = 10 + sqrt(the_genome[physicalStart]);
    }
    
    return d; // limit 0 to infinity 
  }
  
  // Forward force to accelerate the creature, evolved, but (currently) doesn't change anytime durning a wave
  int getForce() {
    return((int)(500+10*the_genome[physicalStart+1])); // -infinity to infinity linear
  }
  
  // This is the base turning force, it is modified by getBehavior() above, depending on what type of object was sensed to start turning
  int getTurningForce() {
    return((int)(100+10*the_genome[physicalStart+2])); // -infinity to infinity linear
  }
  
  // How bouncy a creature is, one of the basic box2D body parameters, no idea how it evolves or if it has any value to the creatures
  float getRestitution() {
    float r = 0;
    r = 0.5 + (0.5 * (the_genome[physicalStart+3]/(1+abs(the_genome[physicalStart+3]))));
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
  
  // Gets the end point of the ith segment/rib/spine on the other side of the creatures body
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
 
  // Mutates every value by a little bit. Biologically speaking a very high mutation rate to foster fast evolution
  void mutate() {
    for (int i = 0; i < totalgenes; i++) {
      the_genome[i] += randomGaussian()*0.3;
    }
  }
}
