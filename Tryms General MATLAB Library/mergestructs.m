function[S] = mergestructs(x)

% merge structs.
% use any number of arguments two merge any number of structs:
%     "mergestructs(x,y,z,...)"

% when several structs have equal fieldnames, the field of the LEFTmost of
% those structs will be preserved, and the others are not included in the output
% struct.

arguments(Repeating)
   x (1,1) struct
end
    L = length(x);
    S = x{1};
    for ii = 2:L
        S = mergestructsTWO(S,x{ii});
    end
end


function[S] = mergestructsTWO(x,y)
% Merge two structs.
% All fields of x stay untouched
% All fields of y that have DIFFERENT names than all fields of x will be
% added to x.
% (all fields of y that have the same name as a field of x will be lost)

Cx = struct2cell(x);
Cy = struct2cell(y);

Fx = string(fieldnames(x));
Fy = string(fieldnames(y));

for i = 1:length(Fx)
    Name = Fx(i);
    ind = find(Fy == Name);
    Cy(ind) = [];
    Fy(ind) = [];
end

S = cell2struct([Cx;Cy],[Fx;Fy]);

end
