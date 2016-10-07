function [algorithms algo_names algo_names_short] = defineFSAlgorithms()

REGRESSION = 0;
CLASSIFICATION = 1;
BOTH = 2;

algorithms = struct;

algorithms(1).name = 'ReliefF';  % ReleifF and RReleifF
algorithms(1).type = BOTH;

algorithms(2).name = 'CFS';  % FSelector implementation works on both
algorithms(2).type = BOTH;

algorithms(3).name = 'Boruta';  % Package docs say both work
algorithms(3).type = BOTH;

algorithms(4).name = 'mRMRe';
algorithms(4).type = CLASSIFICATION;

algorithms(5).name = 'ePLOFS';
algorithms(5).type = BOTH;

algo_names_short = '';
for i=1:length(algorithms)
    algo_names{i} = algorithms(i).name;
    algo_names_short = [algo_names_short algorithms(i).name(1:3)];
end
