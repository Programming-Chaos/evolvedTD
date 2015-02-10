public static class Utilities {
  public double Sigmoid(double x, double lamda, double range_scale) {
    return = range_scale * ( (2.0 / (1 + exp(-1 * x * lamda))) - 1 );    // f(x) = N * ( ______2______  - 1 )   N is the range scaling factor, l is the horizontal scaling factor (steepness of the curve)     
  }                                                                //            ( (1 + e^(-lx))      )   This sigmoid is centered on 0, gives values in the range (-N,N)
} 
