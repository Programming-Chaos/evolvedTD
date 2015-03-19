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
    return (range_scale * ((2.0 / (1 + exp((float)(-1 * x * lambda))) - 1)));
    // f(x) = N * ( ______2______ - 1 ) N is the range scaling factor,
    // l is the horizontal scaling factor (steepness of the curve)

    // ( (1 + e^(-lx)) ) This sigmoid is centered on 0, gives values
    // in the range (-N,N)
  }
}
