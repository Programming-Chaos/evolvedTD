/* SENSORY SYSTEMS

   Here have added feelers evolution, and the ability for each of the
   feelers to detect different things

   Additionally we implemented taste, pain, speed, mass, and energy detection
*/
class Sensory_Systems {
  float []brain_array = new float[1000];

  int ROCK_PRESSURE = 260;
  int CREATURE_PRESSURE = 270;

  int b_pain = 0;
  int b_pain_angle = 1;

  int b_pressure_ground = 5; //not implemented
  int b_pressure_side = 45;
  int b_pressure_feeler = 85;

  int b_temperature = 125;
  int b_temperature_feelers = 165;

  int b_taste_feelers = 205;
  int b_taste = 405;  // should be single
  int b_scent_feelers = 605;

  int b_speed_x = 806;
  int b_speed_y = 807;
  int b_angular = 808;

  //0 -1 current / max fpr energy stats

  int b_energy_reproduction = 809;
  int b_energy_health = 810;
  int b_energy_move = 811;

  int b_mass = 812;
  int b_angle = 813;


  int num_feelers;
  //Pain varaibles
  boolean pain; /*perhaps evolve not to have pain*/
  float pain_current, pain_dampening, pain_threshold;

  //Pressure
  boolean pressure;
  float pressure_ground, pressure_side;
  int pressure_feelers;

  //Temperature feeling
  boolean temperature;
  int temperature_feelers;

  //Taste/Receptors
  int taste_feelers;
  boolean taste;

  //Scent
  int scent_feelers;

  //Speed/balance receptors
  boolean speed = false;
  boolean angular = false;
  boolean mass = false;
  boolean energy = false;
  boolean canPain = false;
  
  float [] apend_angles;
  float [] apend_length;
  float [] pressure_side_ids;

  boolean [] feeler_pressure;
  boolean [] feeler_taste;
  boolean [] feeler_scent;

  Sensory_Systems(Genome g) {
    brain_array = new float[1000];
    
    double can_feel_pain =  Utilities.Sigmoid(g.sum(painTrait), 5, 100);

    if (can_feel_pain > 0) {
      canPain = false;
    }

    double canMass = Utilities.Sigmoid(g.sum(massTrait), 5, 1);
    if (canMass > 0) {
      mass = true;
    }

    double canAngular = Utilities.Sigmoid(g.sum(angularMomentumTrait), 5, 1);
    if (canAngular > 0) {
      angular = true;
    }

    double canSpeed = Utilities.Sigmoid(g.sum(speedTrait), 5, 1);
    if (canSpeed > 0) {
      speed = true;
    }

    double canTaste = Utilities.Sigmoid(g.sum(tasteTrait), 5, 1);
    if (canTaste > 0) {
      taste = true;
    }

    double canEnergy = Utilities.Sigmoid(g.sum(energyTrait), 5, 1);
    if (canEnergy > 0) {
      energy = false;
    }

    Set_Pain(pain, 0, abs((float)Utilities.Sigmoid(g.sum(painDampeningTrait), 5, 1)), abs((float)Utilities.Sigmoid(g.sum(painThresholdTrait), 5, 100))); /*Has pain, pain amount currentlyu, pain_dampening, pain_threshold*/

    num_feelers = (int)abs((float)Utilities.Sigmoid(g.sum(expressedFeelers), 1, 20))*2;

    apend_angles = new float[num_feelers];
    apend_length = new float[num_feelers];
    pressure_side_ids = new float[40];

    feeler_pressure = new boolean[num_feelers];
    feeler_taste = new boolean[num_feelers];
    feeler_scent = new boolean[num_feelers];

    Set_Feeler(g);
  }

  /*For the brain*/
  float [] Get_Brain_Array() { return brain_array; };


  /*Determines what feelers can do and the lengths and angles of each*/
  void Set_Feeler(Genome g) {
    for (int i = 0; i < num_feelers; i=i+2) {
      float angle_1 = abs((float)Utilities.Sigmoid(g.sum(feelers.get(i).angle), 3, PI) - HALF_PI );
      float angle_2;
      
      if (angle_1 < 0) {
        angle_2 = PI + angle_1;
      } else {
        angle_2 = PI - angle_1;
      }
  
      apend_angles[i] = angle_1;
      apend_angles[i+1] = angle_2; 
 
      float len = abs((float)Utilities.Sigmoid(g.sum(feelers.get(i).length), 5, 1000));
      apend_length[i] = len;
      apend_length[i+1] = len;
      

      if (Utilities.Sigmoid(g.sum(feelers.get(i).pressure), 5, 1) > 0) {
        feeler_pressure[i] = true;
        feeler_pressure[i+1] = true;
      } else {
        feeler_pressure[i] = false;
        feeler_pressure[i+1] = false;
      }

      if (Utilities.Sigmoid(g.sum(feelers.get(i).taste), 5, 1) > 0) {
        feeler_taste[i] = true;
        feeler_taste[i+1] = true;
      } else {
        feeler_taste[i] = false;
        feeler_taste[i+1] = false;
      }

      if (Utilities.Sigmoid(g.sum(feelers.get(i).scent), 5, 1) > 0) {
        feeler_scent[i] = true;
        feeler_scent[i+1] = true;
      } else {
        feeler_scent[i] = false;
        feeler_scent[i+1] = false;
      }
    }
  }
  
  /*Goes through each feelers and updates the senses it can interpret*/
  void Update_Senses(float x, float y, float angle) {
    for (int i = 0; i < num_feelers;  i++) {
      Update_Sense(x, y, angle, apend_angles[i], apend_length[i], i);
    }
  }

  /*Update feeler senses*/
  void Update_Sense(float x, float y, float angle, float evolved_angle, float evolved_length, int i) {

    /*Calculate end location of feelers
     */
    float sensorX,sensorY;
    
    sensorX = x + evolved_length * cos(-1 * (angle + PI+evolved_angle));
    sensorY = y + evolved_length * sin(-1 * (angle + PI+evolved_angle));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;

    /*If feeler can feel pressure*/
    if (feeler_pressure[i]) {
      if (environ.checkForRock(sensorX, sensorY) == 1) {
        brain_array[b_pressure_feeler + i] = ROCK_PRESSURE;
      } else if (environ.checkForCreature(sensorX, sensorY) == 1) {
        brain_array[b_pressure_feeler + i] = CREATURE_PRESSURE;
      } else {
        brain_array[b_pressure_feeler + i] = environ.checkForPressure(sensorX, sensorY);
      }
    }

    /*If feeler can taste*/
    if (feeler_taste[i]) {
      int []tmp_taste = environ.checkForTaste(sensorX, sensorY);
      if (tmp_taste != null) {
        brain_array[b_taste_feelers+i] = tmp_taste[0];
        brain_array[b_taste_feelers+i+1] = tmp_taste[1];
        brain_array[b_taste_feelers+i+2] = tmp_taste[2];
        brain_array[b_taste_feelers+i+3] = tmp_taste[3];
        brain_array[b_taste_feelers+i+4] = tmp_taste[4];
      } else {
        brain_array[b_taste_feelers+i] = 0;
        brain_array[b_taste_feelers+i+1] = 0;
        brain_array[b_taste_feelers+i+2] = 0;
        brain_array[b_taste_feelers+i+3] = 0;
        brain_array[b_taste_feelers+i+4] = 0;        
      }
    }
    /*If feeler can pick up smell*/
    if (feeler_scent[i]) {
      brain_array[b_scent_feelers+i] = environ.getScent(sensorX, sensorY);
    }

  }

 /*Sets taste once creature comes in contact with food*/
  void Set_Taste(food f) {
    if (taste) {
      int []tmp_taste = f.getTaste();
      brain_array[b_taste] = tmp_taste[0];
      brain_array[b_taste+1] = tmp_taste[1];
      brain_array[b_taste+2] = tmp_taste[2];
      brain_array[b_taste+3] = tmp_taste[3];
      brain_array[b_taste+4] = tmp_taste[4];
    }
  }
  /*Removes taste from eating*/
  void Remove_Taste() {
    if (taste) {
      brain_array[b_taste] = 0;
      brain_array[b_taste+1] = 0;
      brain_array[b_taste+2] = 0;
      brain_array[b_taste+3] = 0;
      brain_array[b_taste+4] = 0;
    }

  }

  /*This functions calls Draw_Feeler
  for each feeler the creature has*/
  void Draw_Sense(float x, float y, float angle) {
    for (int i = 0; i < num_feelers;  i++) {
      Draw_Feeler(x, y, angle, apend_angles[i], apend_length[i]);
    }
  }

  /*This function draws the feelers for the creature*/
  void Draw_Feeler(float x, float y, float angle, float evolved_angle, float evolved_length) {
    // Draw the "feelers", this is mostly for debugging
    float sensorX,sensorY;
    sensorX = x + evolved_length * cos(-1 * (angle + PI+evolved_angle));
    sensorY = y + evolved_length * sin(-1 * (angle + PI+evolved_angle));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(x, y, sensorX, sensorY);
  }

  /*This is the constructor for the pain*/
  void Set_Pain(boolean _pain, float _curr_pain, float _pain_dampening, float _pain_threshold) {
    pain = _pain;
    pain_dampening = _pain_dampening;
    pain_threshold = _pain_threshold;
    Set_Current_Pain(_curr_pain);
  }


  /*This will set the current amount of pain the creature is currently in
  the creature will only get pain if it is hit by a projectile*/
  void Set_Current_Pain(float _curr_pain) {
    pain_current += _curr_pain;
    if (pain_current > pain_threshold) {
      pain_current = pain_threshold;
    }
  }

  /*Update pain is called in the update creature class to give the pain
  infomration to the brain*/
  void Update_Pain() {
    if (canPain) {
      if (pain_threshold != 0) {
        brain_array[b_pain] = pain_current/pain_threshold;
        pain_current *= pain_dampening;
      }  
    }
  }

  /*Gets the basic stats of the creature such as velocity, mass
  momentum, health and movement*/
  void Set_Stats(creature c) {
    if (speed) {
      brain_array[b_speed_x] = c.body.getLinearVelocity().x;
      brain_array[b_speed_y] = c.body.getLinearVelocity().y;
    }
    if (energy) {
      brain_array[b_energy_reproduction] = c.energy_reproduction / c.max_energy_reproduction;
      brain_array[b_energy_move] = c.energy_locomotion / c.max_energy_reproduction;
      brain_array[b_energy_health] = c.energy_health / c.max_energy_reproduction;
    }

    if (angular) {
      brain_array[b_angular] = c.body.getAngularVelocity();
    }
    if (mass) {
      brain_array[b_mass] = c.body.getMass();
    }

    brain_array[b_angle] = c.body.getAngle();
  }


/* Since fixtures do not work the way I expected I need to do a tricky thing to detect pressure on side
   in the contact and endcontact function in evolveTD, if two creatures touch, a unique key is created, the largest
   is kept and then the ID is added, and the angle is added to the brain*/
   
  void Add_Side_Pressure(int ID, float angle) {
    int i = 0;
    int zero_location;

    while (pressure_side_ids[i] != 0 && pressure_side_ids[i] != ID && i < 39) {
      i++;
    }


    pressure_side_ids[i] = ID;
    brain_array[b_pressure_side + i] = angle;

  }

  void Remove_Side_Pressure(int ID) {
    int i = 0;

    while (pressure_side_ids[i] != ID && i < 39) {
      i++;
    }

    pressure_side_ids[i] = 0;
    brain_array[b_pressure_side + i] = 0;
    i++;

    while ( i < 38  && pressure_side_ids[i] != 0) {
      pressure_side_ids[i-1] = pressure_side_ids[i];
      i++;
    }
  }
}
