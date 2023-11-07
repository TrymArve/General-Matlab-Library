function[area] = Area_of_Circle_band(a,b,R)
   arguments
      a (1,1) double {mustBePositive}
      b (1,1) double {mustBePositive}
      R (1,1) double {mustBePositive} = 1;
   end
   if ~(a<b)
      error('Error: a must be smaller than b.')
   end
   if b > R
      error('Error: b cannor be larger than the radius of the circle.')
   end

   % This function finds the area of a band across a circle, where the band
   % is its edges at distances a and b into the cicle from a common point
   % on the circumference.

   area =  2*(    (1./2.*b.*sqrt(R.^2 - b.^2) + 1./2 .*R.^2.* atan(b./sqrt(R.^2 - b.^2)))...
                - (1./2.*a.*sqrt(R.^2 - a.^2) + 1./2 .*R.^2.* atan(a./sqrt(R.^2 - a.^2)))    );

end