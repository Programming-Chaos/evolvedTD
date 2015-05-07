import java.util.Comparator;

static int creature_count = 0;

class Gamete {
  int xPos, yPos;
  int time;
  int energy;
  creature parent;
  
  Gamete(int x, int y, int e, creature p){
    xPos = x;
    yPos = y;
    time = timesteps;
    energy = e;
    parent = p;
  }

  int getX()             { return xPos; }
  int getY()             { return yPos; }
  int getTime()          { return time; }
  int getEnergy()        { return energy; }
  // TODO: use other gamete from getGametes()
  Chromosome getGamete() { return (Chromosome)parent.genome.getGametes().get(0); }
}

class creature {
  // stats
  int num;               // unique creature identifier
  int[] parents = new int[2];
  int[] grandparents = new int[4];
 
  
  boolean alive;         // dead creatures remain in the swarm to have a breeding chance
  int munchtimer = 0;
  int munchstrength = 50;// should be evolved
  structure munching = null;
  structure munchnext = null;
  float fitness;         // used for selection
  float health;          // 0 health, creature dies
  float maxHealth = 100; // TODO: should be evolved
  int health_regen = 1;  // value to set how much health is regenerated each timestep when energy is spent to regen
  int round_counter;     // counter to track how many rounds/generations the individual creature has been alive
  float baseMaxMovementForce = 4000; //maximum speed without factoring in width and appendages
  float maxMovementForce;
  float baseMaxTorque = 10;
  int hit_indicator = 0; //to create animations on creature impacts

  // timers
  int timestep_counter;  // counter to track how many timesteps a creature has been alive
  int time_in_water;     // tracks how much time the creature spends in water
  int time_on_land;      // tracks how much time the creature spends on land
  int freezeTimer;
  int wiggletimer;
  int wigglelength = 40;
  float wigglestrength = (PI/12);

  // encodes the creature's genetic information
  Genome genome;
  Brain brain;
  float current_actions[];

  // metabolism
  float energy_reproduction;     // energy for gamete produciton
  float energy_locomotion;       // energy for locomotion and similar activites
  float energy_health;           // energy for regeneration
  float max_energy_reproduction; // size of reproductive energy stores
  float max_energy_locomotion;
  float max_energy_health;
  int regen_energy_cost = 5; // value to determine how much regenerating health costs
  float density;
  metabolic_network metabolism;

  // senses/communication
  Sensory_Systems senses;
  boolean scent;     // used to determine if creature is capable of producing scent
  int scentStrength; // how strong the creature's scent is
  int scentType;     // store an integer for different colors
  boolean CreatureScent = false;
  boolean ReproScent = false;
  boolean PainScent = false;
  boolean shocked = false;

  // body
  Body body;
  float angle;
  int numSegments;
  color_network coloration;

  // Reproduction variables
  Vec2 sPos; // Starting position of creature
  int baseGameteCost = 500;    // Gametes base energy cost
  int baseGameteTime = 1;   // Gametes base create time in screen updates.
  int baseGameteEnergy = 500; // Gametes base extra energy
  int gameteTimeLapse = 0;    // Keeps track of time since last gamete

  ArrayList<Gamete> gameteStack = new ArrayList<Gamete>(); // Holds the gametes and their map positions.

  ArrayList<Segment> segments = new ArrayList<Segment>(numSegments);
  ArrayList<Appendage> appendages = new ArrayList<Appendage>(numSegments);

  // Data Collection variables
  float total_energy_space;
  float total_energy_consumed = 0;
  float locomotion_used = 0;
  float reproduction_used = 0;
  float reproduction_passed = 0;
  float health_used = 0;
  int   hits_by_tower = 0;
  int   hp_removed_by_tower = 0;


  class Segment {
    int index;
    float armor;
    float density;
    float restitution;
    Vec2 frontPoint;
    Vec2 backPoint;
    float area;

    Segment(int i) {
      index = i;
      armor = getArmor();
      density = getSegmentDensity();
      density *= armor;
      restitution = getRestitution();
      frontPoint = getFrontPoint();
      backPoint = getBackPoint();
      area = getArea();
    }

    private float getArea() {
      return (((sqrt((frontPoint.x*frontPoint.x)+(frontPoint.y*frontPoint.y))*sqrt((backPoint.x*backPoint.x)+(backPoint.y*backPoint.y)))/2)*(sin(PI/numSegments)));
    }

    private float getArmor() {
      float a = (genome.avg(segmentTraits.get(index).armor));
      if ((1+a) < 0.1) return 0.1;
      return (a+1);
    }

    private float getSegmentDensity() {
      float d = (genome.sum(segmentTraits.get(index).density));
      // if the value is negative, density approaches zero asympototically from 10
      if (d < 0)
        return 10 * (1 / (1 + abs(d)));
      // otherwise, the value is positive and density grows as 10 plus the square
      // root of the evolved value
      return 10 + sqrt(d); // limit 0 to infinity
    }

    private float getRestitution() {
      float r = (genome.sum(segmentTraits.get(index).restitution));
      return 0.5 + (0.5 * (r / (1 + abs(r))));
    }

    private Vec2 getFrontPoint() {
      Vec2 p = new Vec2();
      float endpoint;
      if (index == (numSegments-1)) endpoint = genome.sum(segmentTraits.get(index).appendageSize); // frontmost point is undefined and therefore we use the unused appendageSize trait
      else endpoint = genome.sum(segmentTraits.get(index+1).endPoint);
      int lengthbase = 20;
      float l;
      if (endpoint < 0) {
        l = 1 + (lengthbase-1) * (1.0/(1+abs(endpoint)));
      }
      else {
        l = lengthbase + (2*lengthbase*(endpoint/(1+endpoint)));;
      }
      p.x = (float)(l * Math.sin((index+1)*PI/(numSegments)) );
      p.y = (float)(l * Math.cos((index+1)*PI/(numSegments)) );
      return p;
    }

    private Vec2 getBackPoint() {
      Vec2 p = new Vec2();
      float endpoint = genome.sum(segmentTraits.get(index).endPoint);
      int lengthbase = 20;
      float l;
      if (endpoint < 0) {
        l = 1 + (lengthbase-1) * (1.0/(1+abs(endpoint)));
      }
      else {
        l = lengthbase + (2*lengthbase*(endpoint/(1+endpoint)));;
      }
      p.x = (float)(l * Math.sin((index)*PI/(numSegments)) );
      p.y = (float)(l * Math.cos((index)*PI/(numSegments)) );
      return p;
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  class Appendage {
    int index;
    float size;
    float armor;
    float density;
    float restitution;
    float waterForce;
    float grassForce;
    float mountainForce;
    float angle;
    float spread;
    float frontlength;
    float backlength;
    Vec2 originPoint;
    Vec2 frontPoint;
    Vec2 backPoint;
    float area;

    Appendage(int i) {
      index = i;
      size = getSize();
      if (size>0) {
        armor = getArmor();
        density = getAppendageDensity();
        density *= armor;
        getForces();
        getLengths();
        angle = getAngle();
        spread = getSpread();
        originPoint = getOriginPoint();
        frontPoint = getFrontPoint();
        backPoint = getBackPoint();
        area = getArea();
      }
    }

    private float getSize() {
      float ret = genome.sum(segmentTraits.get(index).appendageSize);
      if (ret < 0) ret *= -1;
      if (ret < 0.3) ret = 0;
      return ret;
    }

    private float getArmor() {;
      float a = (genome.avg(appendageTraits.get(index).armor));
      if ((1+a) < 0.1) return 0.1;
      return (a+1);
    }

    private float getAppendageDensity() {
      float d = (genome.sum(appendageTraits.get(index).density));
      // if the value is negative, density approaches zero asympototically from 10
      if (d < 0)
        return 10 * (1 / (1 + abs(d)));
      // otherwise, the value is positive and density grows as 10 plus the square
      // root of the evolved value
      return 10 + sqrt(d); // limit 0 to infinity
    }

    private float getRestitution() {
      float r = (genome.sum(appendageTraits.get(index).restitution));
      return 0.5 + (0.5 * (r / (1 + abs(r))));
    }

    void getForces() { //mapping function is inverse quadratic
      float water = (genome.avg(appendageTraits.get(index).waterForce));
      waterForce = (((float)-1/(((float)10/9)+(water*water)))+1);
      float grass = (genome.avg(appendageTraits.get(index).grassForce));
      grassForce = (((float)-1/(((float)10/9)+(grass*grass)))+1);
      float mountain = (genome.avg(appendageTraits.get(index).mountainForce));
      mountainForce = (((float)-1/(((float)10/9)+(mountain*mountain)))+1);
    }

    void getLengths() {
      frontlength = ((float)mountainForce*67*size);
      backlength = ((float)grassForce*67*size);
    }
    
    private float getAngle() {
      return (((index+1)*(PI/numSegments)));//(float)(Math.atan((segments.get(index).backPoint.x-segments.get(index).frontPoint.x)/(segments.get(index).backPoint.y-segments.get(index).frontPoint.y)));
    }
    
    private float getSpread() {
      return (0.4*PI*waterForce);
    }

    private Vec2 getOriginPoint() { // point of origin of the appendages is the front point of the associated segment
      return new Vec2(segments.get(index).frontPoint.x, segments.get(index).frontPoint.y);
    }

    private Vec2 getFrontPoint() {
      return new Vec2((float)(frontlength*(Math.sin(spread+angle)))+originPoint.x,
                      (float)(frontlength*(Math.cos(spread+angle)))+originPoint.y);
    }

    private Vec2 getBackPoint() {
      return new Vec2((float)(backlength*(Math.sin((-1*spread)+angle)))+originPoint.x,
                      (float)(backlength*(Math.cos((-1*spread)+angle)))+originPoint.y);
    }

    private float getArea() {
      return (((sqrt(((originPoint.x-frontPoint.x)*(originPoint.x-frontPoint.x))+
                     ((originPoint.y-frontPoint.y)*(originPoint.y-frontPoint.y)))*
                sqrt(((originPoint.x-backPoint.x)*(originPoint.x-backPoint.x))+
                     ((originPoint.y-backPoint.y)*(originPoint.y-backPoint.y))))/2)*(sin(spread)));
    }
  }

  // Constructor, creates a new creature at the given location and angle

  // This constructor is generally only used for the first wave, after
  // that creatures are created from parents.
  creature(float x, float y, float a) {
    angle = a;
    genome = new Genome();
    construct((float)20000, new Vec2(x, y));
  }

  // construct a new creature with the given genome and energy
  creature(Genome g, float e) {
    hit_indicator=0; // starts a creature as not having been hit
    angle = random(0, 2 * PI); // start at a random angle
    genome = g;
    // Currently creatures are 'born' around a circle a fixed distance
    // from the tower. Birth locations should probably be evolved as
    // part of the reproductive strategy and/or behavior
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle),
                        0.45 * worldWidth * cos(angle));
    construct(e, pos);
  }

  // construct a new creature with the given genome, energy and position
  creature(Genome g, float e, Vec2 pos) {
    angle = random(0, 2 * PI); // start at a random angle
    genome = g;
    construct(e, pos);
  }

  void construct(float e, Vec2 pos) { // this function contains all the overlap of the constructors
  
    parents[0] = -1;
    parents[1] = -1;
    grandparents[0] =-1;
    grandparents[1] =-1;
    grandparents[2] =-1;
    grandparents[3] =-1;
    
    
    num = creature_count++;
    senses = new Sensory_Systems(genome);
    brain = new Brain(genome);
    genome.inheritance(num);
    freezeTimer = 0;
    wiggletimer = 0;
    hit_indicator = 0;

    current_actions = new float[brain.OUTPUTS];

    // used for data collection
    sPos = pos.clone();
    total_energy_space = max_energy_locomotion + max_energy_reproduction + max_energy_health;


    numSegments = getNumSegments();
    for (int i = 0; i < numSegments; i++) segments.add(new Segment(i));
    for (int i = 0; i < (numSegments-1); i++) appendages.add(new Appendage(i));

    makeBody(pos);   // call the function that makes a Box2D body
    body.setUserData(this);     // required by Box2D
    density = getCreatureDensity();

    float energy_scale = 500; // scales the max energy pool size
    float max_sum = abs(genome.sum(maxReproductiveEnergy)) + abs(genome.sum(maxLocomotionEnergy)) + abs(genome.sum(maxHealthEnergy));
    max_energy_reproduction = body.getMass() * energy_scale * abs(genome.sum(maxReproductiveEnergy))/max_sum;
    max_energy_locomotion = body.getMass() * energy_scale * abs(genome.sum(maxLocomotionEnergy))/max_sum;
    max_energy_health =  body.getMass() * energy_scale * abs(genome.sum(maxHealthEnergy))/max_sum;
    energy_reproduction = 0;                                // have to collect energy to reproduce
    energy_locomotion = min(e,max_energy_locomotion);       // start with energy for locomotion, the starting amount should come from the gamete and should be evolved
    energy_health = 0;                                      // have to collect energy to regenerate, later this may be evolved
    //println(max_energy_reproduction + " " + max_energy_locomotion + ":" +energy_locomotion + " "+ max_energy_health);  // for debugging
    metabolism = new metabolic_network(genome);
    coloration = new color_network(genome);
    health = maxHealth;         // initial health (probably should be evolved)
    fitness = 0;                // initial fitness
    alive = true;               // creatures begin life alive

    maxMovementForce = baseMaxMovementForce;// - (2*getWidth());
    //if (maxMovementForce < 0) maxMovementForce = 0;
    //for (Appendage app : appendages) maxMovementForce += 50*app.size; // Every appendage contributes to overall movement speed a little, 15 to start out. This encourages the evolution of appendages in the first place.

    scent = setScent();                 // does creature produce scent
    scentStrength = setScentStrength(); // how strong is the scent
    scentType = setScentType();         // what color is the scent
  }

  boolean getScent()     { return scent; }
  int getScentStrength() { return scentStrength; }
  int getScentType()     { return scentType; }

  int setScentType() {
    if (scent) {
      return 1;
    }
    return 0;
  }

  void TurnOnReproScent() {
    if (!scent) {
      return;
    }
    if (genome.sumX(scentTrait) >= 0) {
      ReproScent = true;
      CreatureScent = false;
      PainScent = false;
    }
  }

  void TurnOffReproScent() {
    ReproScent = false;
    if (scent) {
      CreatureScent = true;
    }
  }

  void TurnOnPainScent() {
    if (!scent) {
      return;
    }
    if (genome.sumY(scentTrait) >= 0) {
      ReproScent = false;
      CreatureScent = false;
      PainScent = true;
    }
  }

  void TurnOffPainScent() {
    PainScent = false;
    if (scent) {
      CreatureScent = true;
    }
  }

  // set scentStrength
  int setScentStrength() {
    int s;
    float tmp;
    tmp = genome.avg(scentTrait);
    if (tmp < -1 )
      s = 0;
    else if (tmp >= -1 && tmp < 0 )
      s = 1;
    else if (tmp >= 0 && tmp < 1 )
      s = 2;
    else
      s = 3;
    // mapping function goes here
    return s;
  }

  // function setScent will calculate the creatures scent value
  boolean setScent() {
    float s;
    s = genome.sum(scentTrait);
    // need to add a mapping function here
    if (s >= 0) {
      return true;
    } else {
      return false;
    }
  }

  // returns a vector to the creature's postion
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(body));
  }

  // adds some energy to the creature - called when the creature picks
  // up food/resource
  void addEnergy(int x) {
    float[] inputs = new float[metabolism.getNumInputs()];  // create the input array
    inputs[0] = 1;   // set the input values, starting with a bias
    inputs[1] = energy_reproduction/max_energy_reproduction;
    inputs[2] = energy_locomotion/max_energy_locomotion;
    inputs[3] = energy_health/max_energy_health;
    inputs[4] = round_counter*0.01;  // scale the round counter
    float[] outputs = new float[metabolism.getNumOutputs()];  // create the output array
    metabolism.calculate(inputs,outputs);  // run the network
    //  println(outputs[0] + " " + outputs[1] + " " + outputs[2]);  // debugging output
    float sum = 0;
    for(int i = 0; i < metabolism.getNumOutputs(); i++){
      outputs[i] = abs(outputs[i]);  // set negative outputs to positive - do something more clever later
      sum += outputs[i];  // sum the network outputs
    }
    energy_reproduction += x * outputs[0]/sum;
    energy_locomotion += x * outputs[1]/sum;
    energy_health += x * outputs[2]/sum;
    //    println(x * outputs[0]/sum + " " + x * outputs[1]/sum + " " + x * outputs[2]/sum + " " + ((x * outputs[0]/sum )+ (x * outputs[1]/sum )+ (x * outputs[2]/sum)) );  // for debugging
    energy_reproduction = min(energy_reproduction, max_energy_reproduction);
    energy_locomotion = min(energy_locomotion, max_energy_locomotion);
    energy_health = min(energy_health, max_energy_health);

    // data collection
    total_energy_consumed += x;
  }

  // Mapping from allele value to color is a sigmoid mapping to 0 to
  // 255 centered on 126
  private color getColor(int n) {
    // TODO: refactor for color per segment
    float[] inputs = new float[coloration.getNumInputs()];
    float redColor = genome.sum(redColorTrait);
    float greenColor = genome.sum(greenColorTrait);
    float blueColor = genome.sum(blueColorTrait);
    float alphaColor = genome.sum(alphaTrait);

    int r = 126 + (int)(126*(redColor/(1+abs(redColor))));
    int g = 126 + (int)(126*(greenColor/(1+abs(greenColor))));
    int b = 126 + (int)(126*(blueColor/(1+abs(blueColor))));
    int a = 126 + (int)(126*(alphaColor/(1+abs(alphaColor))));
    inputs[0] = 1;   // bias
    inputs[1] = timestep_counter*0.001;
    inputs[2] = health/maxHealth;
    inputs[3] = time_in_water/(timestep_counter+1); // percentage of time in water
    inputs[4] = r/255;
    inputs[5] = g/255;
    inputs[6] = b/255;
    inputs[7] = a/255;
    inputs[8] = n;
    float[] outputs = new float[coloration.getNumOutputs()];
    coloration.calculate(inputs, outputs);
    float sum = 0;
    for(int i = 0; i < coloration.getNumOutputs(); i++){
      outputs[i] = abs(outputs[i]);
      sum += outputs[i];
    }

    r = r*(1 + (int)outputs[0]);
    g = g*(1 + (int)outputs[1]);
    b = b*(1 + (int)outputs[2]);
    a = a*(1 + (int)outputs[3]);

    /*I turned off alpha value here so I could not draw segmentations on creatures
    The creatures weren't easily visible with a low alpha*/
    return color(r, g, b, 255);
  }

  // Calculate and return the width of the creature
  private float getWidth() {
    // TODO: Move this to creature
    float minX = 0;
    float temp;
    for (int i = 0; i < numSegments-1; i++) {
      temp = segments.get(i).frontPoint.x;
      if (temp < minX) minX = temp;
    }
    return (-2*minX);
  }

  // Calculate and return the length of the creature
  private float getLength() {
    float maxY = 0;
    float minY = 0;
    float temp = segments.get(0).backPoint.y;
    if (temp > maxY) maxY = temp;
    if (temp < minY) minY = temp;
    for (int i = 0; i < numSegments; i++) {
      temp = segments.get(i).frontPoint.y;
      if (temp > maxY) maxY = temp;
      if (temp < minY) minY = temp;
    }
    return (maxY - minY);
  }

  float getMass() {
    return body.getMass();
  }

  float getArmor() {  // gets the sum of armor on all segments and appendages
    float value = 0;
    for (Segment s : segments) {
      value += s.armor;
    }
    for (Appendage a : appendages) {
      value += a.armor;
    }
    return value;
  }

  float getArmorAvg() {  // gets the average of armor on all segments and appendages
    float value = 0;
    float counter = 0;
    for (Segment s : segments) {
      value += s.armor;
      counter++;
    }
    for (Appendage a : appendages) {
      value += a.armor;
      counter++;
    }
    return value/counter;
  }

  float getCreatureDensity() { // gets the creature's density (total mass divided by total area)
    float area = 0;
    for (Segment s : segments) {
      area += s.area;
    }
    for (Appendage a : appendages) {
      if (a.size > 0) area += a.area;
    }
    return (body.getMass()/area);
  }

  // can be from 2 to Genome.MAX_SEGMENTS
  int getNumSegments() {
    int ret = round(genome.sum(expressedSegments) + STARTING_NUMSEGMENTS);
    if (ret < 2)
      return 2;
    if (ret > MAX_SEGMENTS)
      return MAX_SEGMENTS;
    return ret;
  }

  // This function removes the body from the box2d world
  void killBody() {
    // if its no longer alive creature spawns 2 gametes in a     
    // radius of 5 tiles and the body can be killed - otherwise it    
    // still "in" the world.  Have to make sure the body isn't    
    // referenced elsewhere    
      
    // Spawn gametes
    int dx = (int)random(-5, 6); //from -5 to 5 (6 is not included)
    int dy = (int)random(-5, 6);
    int energy = (int) (baseGameteEnergy * (1+genome.avg(gameteEnergy)));
    Vec2 pos = box2d.getBodyPixelCoord(body);
    
    int posX = (int)(pos.x / cellWidth);
    int posY = (int)(pos.y / cellHeight);
    
    gameteStack.add(new Gamete(posX + dx, posY + dy, energy, this));
    gameteStack.add(new Gamete(posX - dx, posY - dy, energy, this));

    // remove reference to creature
    body.setUserData(null);
    for (Fixture f = body.getFixtureList(); f != null; f = f.getNext())
      f.setUserData(null);
    // Delete the body
    box2d.destroyBody(body);
  }

  double getCompat() {
    //return genome.getCompat();
    return 0;
  }

  // This is the base turning force, it is modified by getBehavior()
  // above, depending on what type of object was sensed to start
  // turning
  private int getTurningForce() {
    // -infinity to infinity linear
    return (int)(100 + 10 * genome.sum(turningForce));
  }

  // Returns the amount of turning force (just a decimal number) the
  // creature has evolved to apply when it senses either food, another
  // creature, a rock, or a (food) scent.
  private double getBehavior(Trait trait) {
    return getTurningForce() * genome.sum(trait); // there's a turning force
  }

  void changeHealth(int h) {
    health += h;
    //senses.Set_Current_Pain(-h);
    // increase or decrease this number to lengthen or shorten the
    // animation time on hit
    hit_indicator = 5;
    // data collection
    hits_by_tower++;
    hp_removed_by_tower += h;
  }

  void calcBehavior(){
    for(int i = 0; i<brain.OUTPUTS; i++){
      current_actions[i] = 0;
      for(int j = 0; j<brain.INPUTS; j++){
        current_actions[i] += (senses.brain_array[j]*brain.weights[i][j]);
      }
    }
  }

  // The update function is called every timestep
  // It updates the creature's postion, including applying turning torques,
  // and checks if the creature has died.
  void update() {
    if (!alive) { // dead creatures don't update
      return;
    }
    Vec2 pos2 = box2d.getBodyPixelCoord(body);
    float a = body.getAngle();

    wiggletimer++;
    if (wiggletimer == wigglelength) wiggletimer = 0;

    calcBehavior();
    timestep_counter++;
    float m = body.getMass();
    float f = 0;
    double torque = 0;
    
    munching = munchnext;
    if (munching != null) {
      if (munchtimer == 50) {
        if(current_actions[2] > 0.0) { // if the creature is hungry
          if (!invinciblestructures) {
            if (munching.type == 'b') {
              if (munching.f.shield < munchstrength) { // this bite will deplete the last of the shield
                if (munching.f.health < munchstrength) { // this bite will kill the structure
                  addEnergy(200*round(munching.f.health));
                  munching.f.health = 0;
                }
                else {
                  munching.f.health -= (munchstrength-munching.f.shield);
                  addEnergy(200*munchstrength);
                }
                munching.f.shield = 0;
              }
              else {
                munching.f.shield -= munchstrength;
                addEnergy(200*munchstrength); // munching a bioreactor is valuable
              }
              //senses.Set_Taste(munching.f);
              if (munching.f.health == 0) munchnext = null;
            }
            else {
              if (munching.t.shield < munchstrength) { // this bite will deplete the last of the shield
                if (munching.t.health < munchstrength) { // this bite will kill the structure
                  addEnergy(40*round(munching.t.health));
                  munching.t.health = 0;
                }
                else {
                  munching.t.health -= (munchstrength-munching.t.shield);
                  addEnergy(40*munchstrength);
                }
                munching.t.shield = 0;
              }
              else {
                munching.t.shield -= munchstrength;
                addEnergy(40*munchstrength); // munching a tower is less valuable than munching a bioreactor
              }
              //senses.Set_Taste(munching.t);
              if (munching.t.health == 0) munchnext = null;
            }
          }
          if (playSound) PlaySounds( "Munch_0" + int(random(1,4)) );
        }
        munchtimer = 0;
      }
      munchtimer++;
    }

    if (freezeTimer == 0) {
      //if (!body.isActive())body.setActive(true);
      //if (body.getType() == BodyType.STATIC)body.setType(BodyType.DYNAMIC);

      torque = current_actions[0];

      //torque = current_actions[0]*baseMaxTorque;

      // force is a percentage of max movement speed from 10% to 100%
      // depending on the output of the neural network in current_actions[1], the movement force may be backwards
      // as of now the creatures never completely stop moving

      f = (maxMovementForce * Utilities.MovementForceSigmoid(current_actions[1]));

      // force is scaled to a percentage of max movement speed between 10% and 100% asymptotically approaching 100%
      // force is negative if current action is negative, positive if it's positive (allows for backwards movement)

      int switchnum;
      if (environ.checkForLiquid((double)pos2.x, (double)pos2.y) == 1) {
        time_in_water++;
        switchnum = 0;
      }
      else if (environ.checkForMountain((double)pos2.x, (double)pos2.y) == 1) switchnum = 1;
      else switchnum = 2;

      float base = f;

      // appendages will change the force depending on the environment
      for (Appendage app : appendages) {
        if (app.size > 0) { // if the appendage exists
          switch (switchnum) {
          case 0: // if the creature's center is in water
            f -= (base*app.grassForce*app.size)/numSegments;
            f += (2*base*app.waterForce*app.size)/numSegments;
            f -= (base*app.mountainForce*app.size)/numSegments;
            break;
          case 1: // if the creature's center is on a mountain
            f -= (base*app.grassForce*app.size)/numSegments;
            f -= (base*app.waterForce*app.size)/numSegments;
            f += (2*base*app.mountainForce*app.size)/numSegments;
            break;
          case 2: // if the creature's center is on grass
            f += (2*base*app.grassForce*app.size)/numSegments;
            f -= (base*app.waterForce*app.size)/numSegments;
            f -= (base*app.mountainForce*app.size)/numSegments;
            break;
          }
        }
      }
      body.applyTorque((float)torque);
  
      if (energy_locomotion > 0) { // If there's energy left apply force
        body.applyForce(new Vec2(f * cos(a - (PI*1.5)), f * sin(a - (PI*1.5))), body.getWorldCenter());
        energy_locomotion = energy_locomotion - abs(2 + (f * 0.005));   // moving uses locomotion energy
        energy_locomotion = (energy_locomotion - abs((float)(torque * 0.0001)));
  
        // data collection
        locomotion_used += (abs(2 + (f * 0.005)) + abs((float)(torque * 0.0001)));
      }
  
      senses.Update_Senses(pos2.x, pos2.y, a);
      // Creatures that run off one side of the world wrap to the other side.
      if (pos2.x < -0.5 * worldWidth) {
        pos2.x += worldWidth;
        body.setTransform(box2d.coordPixelsToWorld(pos2), a);
      }
      if (pos2.x > 0.5 * worldWidth) {
        pos2.x -= worldWidth;
        body.setTransform(box2d.coordPixelsToWorld(pos2), a);
      }
      if (pos2.y < -0.5 * worldHeight) {
        pos2.y += worldHeight;
        body.setTransform(box2d.coordPixelsToWorld(pos2), a);
      }
      if (pos2.y > 0.5 * worldHeight) {
        pos2.y -= worldHeight;
        body.setTransform(box2d.coordPixelsToWorld(pos2), a);
      }
  
      // If a creature runs our of locomotion energy it starts to lose health
      // It might make more sense to just be based on health energy, but creatures start with zero health energy and health energy doesn't always decrease
      if(energy_locomotion <= 0) {
        health = health -1;
      }
    }
    else freezeTimer--;
    // Angular velocity is reduced each timestep to mimic friction (and keep creatures from spinning endlessly)
    body.setAngularVelocity(body.getAngularVelocity() * 0.99);

    // if out of health have the creature "die". Stops participating
    // in the world, still exists for reproducton
    if (health <= 0) {
      alive = false;
      // if its no longer alive the body can be killed - otherwise it
      // still "in" the world.  Have to make sure the body isn't
      // referenced elsewhere
      
      // Destroy Body
      killBody();
    }


    // Gamete production
    // if creature has enough energy and enough time has passed,
    // lay a gamete at current position on the map.
    if (gameteTimeLapse > baseGameteTime + genome.avg(gameteTime)
        && energy_reproduction > (baseGameteCost + genome.avg(gameteCost)
                                  + baseGameteEnergy + genome.avg(gameteEnergy))) {

      // Get the tile position of the creature
      int xPos = (int) (box2d.getBodyPixelCoord(body).x / cellWidth);
      int yPos = (int) (box2d.getBodyPixelCoord(body).y / cellHeight);
      int energy = (int) (baseGameteEnergy * (1+genome.avg(gameteEnergy)));

      // Create gamete and place in gameteSack
      Gamete g = new Gamete(xPos, yPos, energy, this);
      gameteStack.add(g);

      // remove energy from creature
      energy_reproduction -= (baseGameteCost * (1+genome.avg(gameteCost)) + baseGameteEnergy * (1+genome.avg(gameteEnergy)));
      reproduction_used += (baseGameteCost * (1+genome.avg(gameteCost)));
      reproduction_passed += (baseGameteEnergy * (1+genome.avg(gameteEnergy)));

      gameteTimeLapse = 0;
    }
    else gameteTimeLapse++;


    // Spends energy devoted to health regen to increase the
    // creature's health over time
    if (energy_health > 0 && health < maxHealth) {
      health = health + health_regen;
      energy_health = energy_health - regen_energy_cost;

      // data collection
      health_used += regen_energy_cost;
    }
  }

  // Called every timestep (if the display is on) draws the creature
  void display() {
    if (!alive) { // dead creatures aren't displayed
      return;
    }
    //float sw = 1;
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();
    
    if (hit_indicator > 0) { //makes the animation show up when hit
      fill (153,0,0);
      ellipse (pos.x, pos.y, getWidth()+15, getWidth()+15); //this draws the animation when the creature gets hit. Animation is a circle right now
      hit_indicator=hit_indicator-1; //this counts down each timestep to make the animation dissapear
    }
    
    PGraphics pg;
    pg = createGraphics(100, 100);
    
    pg.beginDraw();
    PolygonShape ps; // Create a polygone variable
    // set some shape drawing modes
    rectMode(CENTER);
    ellipseMode(CENTER);

    pushMatrix();// Stores the current drawing reference frame
    translate(pos.x, pos.y);  // Move the drawing reference frame to the creature's position
    rotate(-a);  // Rotate the drawing reference frame to point in the direction of the creature
    
    for(Fixture f = body.getFixtureList(); f != null; f = f.getNext()) {  // While there are still Box2D fixtures in the creature's body, draw them and get the next one
      if (f.getUserData().getClass() == Segment.class) {
        fill(getColor(((Segment)f.getUserData()).index)); // Get the creature's color

        ps = (PolygonShape)f.getShape();  // From the fixture list get the fixture's shape
        beginShape();   // Begin drawing the shape
        //strokeWeight(.1);
        // noStroke();
        Vec2 v;
        Vec2 vorig;
        float len;
        for (int i = 0; i < 3; i++) {
          v = box2d.vectorWorldToPixels(ps.getVertex(i));  // Get the vertex of the Box2D polygon/fixture, translate it to pixel coordinates (from Box2D coordinates)
          vertex(v.x, v.y);  // Draw that vertex
        }
        endShape(CLOSE);
      }
      if (f.getUserData().getClass() == Appendage.class) {
        fill(getColor(((Appendage)f.getUserData()).index)); // Get the creature's color

        ps = (PolygonShape)f.getShape(); // From the fixture list get the fixture's shape
        //strokeWeight(.1);
        // noStroke();
        Vec2 vorig = ((Appendage)f.getUserData()).originPoint;
        float centerangle;
        if (((Appendage)f.getUserData()).index % 2 == 0) centerangle = (((Appendage)f.getUserData()).angle+(((float)((abs(wiggletimer-(wigglelength/2)))-(wigglelength/4))/(wigglelength/4))*wigglestrength));
        else centerangle = (((Appendage)f.getUserData()).angle-(((float)((abs(wiggletimer-(wigglelength/2)))-(wigglelength/4))/(wigglelength/4))*wigglestrength));
        Vec2 v1 = new Vec2((float)(-1*((Appendage)f.getUserData()).frontlength*(Math.sin(centerangle+((Appendage)f.getUserData()).spread)))+vorig.x,
                           (float)(((Appendage)f.getUserData()).frontlength*(Math.cos(centerangle+((Appendage)f.getUserData()).spread)))+vorig.y);
        Vec2 v2 = new Vec2((float)(-1*((Appendage)f.getUserData()).backlength*(Math.sin(centerangle-((Appendage)f.getUserData()).spread)))+vorig.x,
                           (float)(((Appendage)f.getUserData()).backlength*(Math.cos(centerangle-((Appendage)f.getUserData()).spread)))+vorig.y);
        beginShape();   // Begin drawing the shape
        vertex(vorig.x,vorig.y);
        vertex(v1.x,v1.y);
        vertex(v2.x,v2.y);
        endShape(CLOSE);
        beginShape();   // Begin drawing the shape for the opposite side of the body
        vertex(-1*vorig.x,vorig.y);
        vertex(-1*v1.x,v1.y);
        vertex(-1*v2.x,v2.y);
        endShape(CLOSE);
      }
    }

    stroke(10);
    //strokeWeight(1);

    // Add some eyespots
    Vec2 eye = segments.get(round(numSegments*0.74)).frontPoint;;
    senses.Draw_Eyes(eye, this);

    popMatrix();
    
    
    if (freezeTimer > 0) {
      pushMatrix();
      hint(DISABLE_DEPTH_TEST);
      translate(pos.x, pos.y);
      rotate(-a);
      fill (0,200,255,150);
      beginShape();
      for (int i = segments.size()-1; i >= 0; i--) {
        vertex((segments.get(i).frontPoint.x)*1.2, (segments.get(i).frontPoint.y)*1.2);
      }
      for (int i = 0; i < segments.size(); i++) {
        vertex((-1*segments.get(i).backPoint.x)*1.2, (segments.get(i).backPoint.y)*1.2);
      }
      endShape(CLOSE);
      hint(ENABLE_DEPTH_TEST);
      popMatrix();
    }

    pushMatrix(); // Draws a "health" bar above the creature
    translate(pos.x, pos.y);
    noFill();
    //stroke(0);
    // get the largest dimension of the creature
    int offset = (int)max(getWidth(), getLength());
    rect(0, -1 * offset, 0.1 * maxHealth, 3); // draw the health bar that much above it
    fill(0, 0, 255);
    rect(0, -1 * offset, 0.1 * health, 3);
    //Text to display the round counter of each creature for debug purposes
    //text((int)round_counter, 0.2*width,-0.25*height);
    popMatrix();
    
    pushMatrix(); // Draws a "energy" bar above the creature
    translate(pos.x, pos.y);
    noFill();
    stroke(1000);
    // get the largest dimension of the creature
    int offset2 = (int)max(getWidth(), getLength());
    rect(0, -1.1 * offset2, 0.1 * (max_energy_reproduction+max_energy_health+max_energy_locomotion)*0.02, 5); // draw the energy bar that much above it
    //noStroke();
    fill(255, 0, 0);
    rect(0, -1.1 * offset2, 0.1 * (energy_reproduction+energy_health+energy_locomotion)*0.02, 5);
    //Text to display the round counter of each creature for debug purposes
    //text((int)round_counter, 0.2*width,-0.25*height);
    popMatrix();
  }

  // This function makes a Box2D body for the creature and adds it to the box2d world
  void makeBody(Vec2 center) {
    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();  // Define a new Box2D body object
    bd.type = BodyType.DYNAMIC;  // Make the body dynamic (Box2d bodies can also be static: unmoving)
    bd.position.set(box2d.coordPixelsToWorld(center));  // set the postion of the body
    bd.linearDamping = 0.999;  // Give it some friction, could be evolved
    bd.setAngle(angle);      // Set the body angle to be the creature's angle
    body = box2d.createBody(bd);  // Create the body, note that it currently has no shape

    // Define a polygon object, this will be used to make the body fixtures
    PolygonShape sd;

    Vec2[] vertices3;  // Define an array of (3) vertices that will be used to define each fixture

    // For each segment
    for (int i = 0; i < numSegments; i++) {
      sd = new PolygonShape();  // Create a new polygon

      vertices3  = new Vec2[3];  // Create an array of 3 new vectors

      // Next create a segment, pie slice, of the creature by defining
      // 3 vertices of a polygon

      // First vertex is at the center of the creature
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0, 0));
      // Second and third vertices are evolved, so get from the genome
      Vec2 front = segments.get(i).frontPoint;
      Vec2 back = segments.get(i).backPoint;
      vertices3[1] = box2d.vectorPixelsToWorld(front);
      vertices3[2] = box2d.vectorPixelsToWorld(back);

      // sd is the polygon shape, create it from the array of 3 vertices
      sd.set(vertices3, vertices3.length);
      // Create a new Box2d fixture
      FixtureDef fd = new FixtureDef();
      // Give the fixture a shape = polygon that was just created
      fd.shape = sd;
      fd.density = segments.get(i).density;
      fd.restitution = segments.get(i).restitution;
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
      fd.userData = segments.get(i);
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body

      // now tweak and repeat for the symmetrically opposite fixture
      front.x *= -1;
      back.x *= -1;
      vertices3[1] = box2d.vectorPixelsToWorld(front);
      vertices3[2] = box2d.vectorPixelsToWorld(back);
      sd.set(vertices3, vertices3.length);
      fd.shape = sd;
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body

      if (i == (numSegments-1))break;
      if (appendages.get(i).size > 0) {
        Vec2 orig = appendages.get(i).originPoint;
        vertices3[0] = box2d.vectorPixelsToWorld(orig);
        front = appendages.get(i).frontPoint;
        back = appendages.get(i).backPoint;
        vertices3[1] = box2d.vectorPixelsToWorld(front);
        vertices3[2] = box2d.vectorPixelsToWorld(back);
        sd.set(vertices3, vertices3.length);
        fd.shape = sd;
        fd.density = appendages.get(i).density;
        fd.restitution = appendages.get(i).restitution;
        fd.userData = appendages.get(i);
        body.createFixture(fd);  // Create the actual fixture, which adds it to the body

        // now tweak and repeat for the symmetrically opposite fixture
        orig.x *= -1;
        vertices3[0] = box2d.vectorPixelsToWorld(orig);
        front.x *= -1;
        back.x *= -1;
        vertices3[1] = box2d.vectorPixelsToWorld(front);
        vertices3[2] = box2d.vectorPixelsToWorld(back);
        sd.set(vertices3, vertices3.length);
        fd.shape = sd;
        body.createFixture(fd);  // Create the actual fixture, which adds it to the body
      }
    }
  }
}
