// Copyright (C) 2015 evolveTD Copyright Holders

/*  Public Utilities class to put some useful functions 
 *
 */

public static class Utilities {
  
  
  /// Sigmoid function
  /// @desc This function maps (-inf,inf) to (-N,N).  Useful to limit a trait's range in the genome
  /// @param(x): The value to map
  /// @param(lambda): The steepness of the curve
  /// @param(range_scale): The value of the asymptote.  This is the N described above
  
  public static double Sigmoid(double x, double lambda, double range_scale) {
    return (range_scale * ( (2.0 / (1 + exp((float)(-1 * x * lambda))) - 1 )));    // f(x) = N * ( ______2______  - 1 )   N is the range scaling factor, l is the horizontal scaling factor (steepness of the curve)     
  }                                                                                //            ( (1 + e^(-lx))      )   This sigmoid is centered on 0, gives values in the range (-N,N)
  
  public static float MovementForceSigmoid(float x) {
    return (x<0 ? (((float)1/(((float)10/9)+((x/50)*(x/50))))-1) : (((float)-1/(((float)10/9)+((x/50)*(x/50))))+1));
  }
  //The MovementForceSigmoid function returns a number between 0.1 and 1, or -0.1 and -1. if the input is zero, the output is positive 0.1.
  //This function serves to take the output of the neural network and turn it into a percentage that can be applied to a creature's maximum movement speed.
  //In this way, the brain can decide how much of the creature's potential to take advantage of, while never exceeding the creature's physical capabilities.
  //If the brain outputs 50 or negative 50, the function will return 50% or negative 50%. If the brain outputs 100 or -100, the creature will move at 80% speed forward or backward respectively.
  //If the brain outputs around 250 or more, the creature's speed will be pretty close to 100%, although it will never be 100% since the function approaches 1 asymptotically.
  //The return value is never zero, so the creatures can never completely stop. This is to prevent stagnation, because if the creature isn't moving, 
  //                                                                  the sensory inputs aren't going to change much, and the brain will never decide to start moving again.
  //All neural networks need a sigmoid function to make useful decisions, and this is it. For movement speed anyway, more will be needed in the future for other decisions.
  
}


