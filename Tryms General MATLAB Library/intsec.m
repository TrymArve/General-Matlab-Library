%{
This function finds the point where two 2D-lines intersect.
Provide the two points on both lines:
Line a: 
   - a1 = (a1_x, a1_y)
   - a2 = (a2_x, a2_y)
Line b:
   - b1 = (b1_x, b1_y)
   - b2 = (b2_x, b2_y)

They intersect at (intersection(1), intersection(2)).
%}


function intersection = intsec(a1,a2,b1,b2)
   th = ( (b1(2) - a1(2))*(a2(1) - a1(1)) - (b1(1) - a1(1))*(a2(2) - a1(2)) ) / ( (b2(1) - b1(1))*(a2(2) - a1(2)) - (b2(2) - b1(2))*(a2(1) - a1(1)) );
   intersection = b1*(1-th) + b2*th;
end