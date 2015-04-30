/* SENSORY SYSTEMS

   Here have added feelers evolution, and the ability for each of the
   feelers to detect different things

   Additionally we implemented taste, pain, speed, mass, and energy detection
*/


class Sensory_Systems {
  float[] brain_array; /* TODO: reconcile with brain.pde? */
  float[] feeler_angles;
  float[] feeler_length;
  boolean[] feeler_scent;
  
  int b_scent_feelers = 0;
  int num_feelers;
  int scent_feelers;

  color color_of_eyes;
  
  Sensory_Systems(Genome g) {
    brain_array = new float[Brain.INPUTS];
    
    color_of_eyes = color(abs((float)Utilities.Sigmoid(g.sum(redEyeColor), 5, 255)), 
          abs((float)Utilities.Sigmoid(g.sum(blueEyeColor), 5, 255)), 
          abs((float)Utilities.Sigmoid(g.sum(greenEyeColor), 5, 255)));
    
    for (int c = 0; c < Brain.INPUTS; c++)
      brain_array[c] = 0;
    
    num_feelers = 2;

    feeler_angles = new float[num_feelers];
    feeler_length = new float[num_feelers];
    feeler_scent = new boolean[num_feelers];

    Set_Feeler(g);
  }

  /* Determines what feelers can do and the lengths and angles of each */
  void Set_Feeler(Genome g) {
    float angle_1 = 0;
    float angle_2 = 0 ;
    
    for (int i = 0; i < num_feelers; i=i+2) {
      if ( i == 0) {
         angle_1 = 5*QUARTER_PI;;
      } else if (i == 2) {
         angle_1 = 0;
      } else if (i == 4) {
        angle_1 = HALF_PI;
      }
     
      if (angle_1 == HALF_PI) {
       angle_2 = PI+ HALF_PI; 
      }  else if (angle_1 < 0) {
        angle_2 = PI + angle_1;
      } else {
        angle_2 = PI - angle_1;
      }
  
      feeler_angles[i] = angle_1;
      feeler_angles[i+1] = angle_2; 
 
      float len = 100;
      feeler_length[i] = len;
      feeler_length[i+1] = len;
      
      feeler_scent[i] = true;
      feeler_scent[i+1] = true;
      
    }
  }
  
  /*Goes through each feelers and updates the senses it can interpret*/
  void Update_Senses(float x, float y, float angle) {
    for (int i = 0; i < num_feelers;  i++) {
      Update_Sense(x, y, angle, feeler_angles[i], feeler_length[i], i);
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
        /*If feeler can pick up smell*/
    if (feeler_scent[i]) {
      float env_scent = environ.getScent(sensorX, sensorY);
      if (env_scent != 0) {
        brain_array[b_scent_feelers + i] = pow(log(env_scent),2);
      }
    }

}
  
  void Draw_Eyes(Vec2 eye, creature c) {
    int compress;
    
    /*Compression when the creatures lose energy in locomotion*/
    if (random(1) < .05) {
       compress = 1;
    } else {
      compress = ((int)((num_feelers)*(c.energy_locomotion / c.max_energy_locomotion)))+3;
    }
    
    fill(color_of_eyes);
    
    ellipse(eye.x, eye.y, num_feelers+5, compress);
    ellipse(-1 * eye.x, eye.y, num_feelers+5, compress);
    
    fill(255);
 
    if (compress < 3) {
      ellipse(eye.x, eye.y - 1, 2, 2);
      ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    } else {
      ellipse(eye.x, eye.y - 1, 2, 2);
      ellipse(-1 * eye.x, eye.y - 1, 2, 2);  
    }
  }
 /*Sets taste once creature comes in contact with food*/






  /*This functions calls Draw_Feeler
  for each feeler the creature has*/
  void Draw_Sense(float x, float y, float angle) {
    for (int i = 0; i < num_feelers;  i++) {
      Draw_Feeler(x, y, angle, feeler_angles[i], feeler_length[i]);
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
    textSize(25);
    text(str(environ.getScent(sensorX, sensorY)), sensorX, sensorY);
  }
}
