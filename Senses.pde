/* SENSORY SYSTEMS 

Here have added feelers evolution, and the ability for each of the
feelers to detect different things

Additionally we implemented taste, pain, speed, mass, and energy detection*/




import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.AABB;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;


class Sensory_Systems {

  float [] brain_array;

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

  
  int num_appendages;
  //Pain varaibles
  boolean pain; /*perhaps evolve not to have pain*/
  float pain_current, pain_dampening, pain_threshold; 
  
  //Pressure
  boolean pressure;
  float pressure_ground, pressure_side;
  int pressure_appendages;
  
  //Temperature feeling
  boolean temperature;
  int temperature_appendages;
 
 //Taste/Receptors
  int taste_appendages;
  boolean taste;

  //Scent
  int scent_appendages;
  
  //Speed/balance receptors
  boolean speed = false;
  boolean angular = false;
  boolean mass = false;
  boolean energy = false;
  float [] apend_angles;
  float [] apend_length;
  float [] pressure_side_ids;
  
  boolean [] appendage_pressure;
  boolean [] appendage_taste;
  boolean [] appendage_scent;
  
  Sensory_Systems(Genome g) {
    double can_feel_pain = Utilities.Sigmoid(g.sum(painTrait), 5, 1);
    boolean canPain = false;
    
    if (can_feel_pain > 0) {
        canPain = true;
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
        energy = true;
    }

    Set_Pain(pain, 0, abs((float)Utilities.Sigmoid(g.sum(painDampeningTrait), 5, 1)), abs((float)Utilities.Sigmoid(g.sum(painThresholdTrait), 5, 100))); /*Has pain, pain amount currentlyu, pain_dampening, pain_threshold*/
    
    num_appendages = (int)abs((float)Utilities.Sigmoid(g.sum(expressedAppendages), 10, 3));
    
    apend_angles = new float[num_appendages];
    apend_length = new float[num_appendages];
    pressure_side_ids = new float[40];
    
    brain_array = new float[1000];
    appendage_pressure = new boolean[num_appendages];
    appendage_taste = new boolean[num_appendages];
    appendage_scent = new boolean[num_appendages];

    Set_Appendage(g);
  }
  
  float [] Get_Brain_Array() { return brain_array; };
  
  void Set_Appendage(Genome g) {
   for (int i = 0; i < num_appendages; i++) {

    apend_angles[i]= abs((float)Utilities.Sigmoid(g.sum(appendages.get(i).angle), 3, 2*PI));
    apend_length[i] = abs((float)Utilities.Sigmoid(g.sum(appendages.get(i).length), 5, 100));
    
    if (Utilities.Sigmoid(g.sum(appendages.get(i).pressure), 5, 1) > 0) {
      appendage_pressure[i] = true;
    } else {
      appendage_pressure[i] = true;
    }
    
    if (Utilities.Sigmoid(g.sum(appendages.get(i).taste), 5, 1) > 0) {
      appendage_taste[i] = true;
    } else {
      appendage_taste[i] = false;
    }
    
    if (Utilities.Sigmoid(g.sum(appendages.get(i).scent), 5, 1) > 0) {
      appendage_scent[i] = true;
    } else {
     appendage_scent[i] = false;
    }
    }
  }
  void Update_Senses(float x, float y, float angle) {
    for (int i = 0; i < num_appendages;  i++) {
      Update_Sense(x, y, angle, apend_angles[i], apend_length[i], i);
   }
  }
  
  void Update_Sense(float x, float y, float angle, float evolved_angle, float evolved_length, int i) {
    
    float sensorX,sensorY;
    sensorX = x + evolved_length * cos(-1 * (angle + PI+evolved_angle));
    sensorY = y + evolved_length * sin(-1 * (angle + PI+evolved_angle));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
  
    if (appendage_pressure[i]) {
      if (environ.checkForRock(sensorX, sensorY) == 1) {
        brain_array[b_pressure_feeler + i] = ROCK_PRESSURE;
      } else if (environ.checkForCreature(sensorX, sensorY) == 1) {
        brain_array[b_pressure_feeler + i] = CREATURE_PRESSURE;
      } else {
        brain_array[b_pressure_feeler + i] = environ.checkForPressure(sensorX, sensorY);
      }
    }


    if (appendage_taste[i]) {
      int []tmp_taste = environ.checkForTaste(sensorX, sensorY);
      if (tmp_taste != null) {
        brain_array[b_taste_feelers+i] = tmp_taste[0];
        brain_array[b_taste_feelers+i+1] = tmp_taste[1];
        brain_array[b_taste_feelers+i+2] = tmp_taste[2];
        brain_array[b_taste_feelers+i+3] = tmp_taste[3];
        brain_array[b_taste_feelers+i+4] = tmp_taste[4];
      }
        
    }

    if (appendage_scent[i]) {
      brain_array[b_scent_feelers+i] = environ.getScent(sensorX, sensorY);
    }
  
  }
  
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
  
  void Remove_Taste() {
    if (taste) {
      brain_array[b_taste] = 0;
      brain_array[b_taste+1] = 0;
      brain_array[b_taste+2] = 0;
      brain_array[b_taste+3] = 0;
      brain_array[b_taste+4] = 0;
    } 

  }
  
  
  void Draw_Sense(float x, float y, float angle) {
   for (int i = 0; i < num_appendages;  i++) {
      Draw_Appendage(x, y, angle, apend_angles[i], apend_length[i]);
   }
  }
  
  
  void Draw_Appendage(float x, float y, float angle, float evolved_angle, float evolved_length) {
    // Draw the "feelers", this is mostly for debugging
    float sensorX,sensorY;
    // Note that the length (50) and angles PI*40 and PI*60 are the same as when calculating the sensor postions in getTorque()
    sensorX = x + evolved_length * cos(-1 * (angle + PI+evolved_angle));
    sensorY = y + evolved_length * sin(-1 * (angle + PI+evolved_angle));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(x, y, sensorX, sensorY);
    
  }
  
  void Set_Pain(boolean _pain, float _curr_pain, float _pain_dampening, float _pain_threshold) {
    pain = _pain;
    pain_dampening = _pain_dampening;
    pain_threshold = _pain_threshold;
    Set_Current_Pain(_curr_pain);    
  }
  
  void Set_Current_Pain(float _curr_pain) {
    pain_current += _curr_pain;
    if (pain_current > pain_threshold) {
       pain_current = pain_threshold;
    }
  }
  
  void Update_Pain() {
   if (pain) {
     brain_array[b_pain] = pain_current/pain_threshold;
     pain_current *= pain_dampening;
   }
  }

  
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
   
   void Add_Side_Pressure(int ID, float angle) {
     int i = 0;
     int zero_location;

     while (pressure_side_ids[i] != 0 && pressure_side_ids[i] != ID) {
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
