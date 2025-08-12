%% Test script for structor4

fresh

% Create nested struct
S.a = 1:3;
S.b.bb = [10 11; 12 13; 14 15];
S.b.aa.ccc = [100 200];
S.c = 99;

%% Create structor4 instance
C = structor4(S);

%------------------ Basic struct interface ------------------%
disp('--- Basic struct read ---');
disp(C.str.a);
disp(C.str.b.bb);
disp(C.str.b.aa.ccc);
disp(C.str.c);

% Modify struct and check reflection in vector
disp('--- Struct write reflection in vec ---');
C.str.a(2) = 999;
disp('Vec after struct write:');
disp(C.vec());

%------------------ Basic vector interface ------------------%
disp('--- Vector read ---');
disp(C.vec());

disp('--- Vector write reflection in struct ---');
C.vec(1) = -123;
disp('Struct after vec write:');
disp(C.str.a);

%------------------ Traversal & mix tests ------------------%
mixOptions = ["bulk","row","column","scalar"];
structOptions = ["first-fields-first","shallow-fields-first","bredth-to-first"];

for m = mixOptions
    for sOpt = structOptions
        fprintf('\n=== mix=%s | structure=%s ===\n', m, sOpt);
        C = structor4(S); % reset
        C.mix = m;
        C.structure = sOpt;
        if sOpt == "bredth-to-first"
            C.default_depth = 1; % change if you want
        end
        v1 = C.vec(); % get vector
        disp(v1.');
        % Change first element and check reflection
        C.vec(1) = C.vec(1) + 1000;
        fprintf('First field after vec edit: %g\n', C.str.a(1));
    end
end

disp('--- All tests complete ---');
