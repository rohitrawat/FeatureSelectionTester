function evaluateMethod(training_file, validation_file, N, M, isClassification, testing_file, options, results_base, method_name)

addpath('/home/rohit/Dropbox/PLN2012/test_noise_removal');

feature_results_file = [results_base '_feature_order.txt'];

if(N>10)
    points = 10;
else
    points = N;
end
N1_values = round(linspace(1, double(N), points));
o_values = cell(1, points);

if(strcmpi(method_name, 'ReliefF'))
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/feature_selection.R "%s" %d %d %d ReliefF "%s" "%s"', training_file, N, M, isClassification, validation_file, feature_results_file);
    disp(cmd);
    system(cmd);
    o = csvread(feature_results_file)
    
    o_values = make_nested_subsets(o, N1_values);
elseif(strcmpi(method_name, 'Boruta'))
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/feature_selection.R "%s" %d %d %d Boruta "%s" "%s"', training_file, N, M, isClassification, validation_file, feature_results_file);
    disp(cmd);
    system(cmd);
    o = csvread(feature_results_file)
    
    o_values = make_nested_subsets(o, N1_values);
elseif(strcmpi(method_name, 'CFS'))
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/feature_selection.R "%s" %d %d %d CFS "%s" "%s"', training_file, N, M, isClassification, validation_file, feature_results_file);
    disp(cmd);
    system(cmd);
    o = csvread(feature_results_file)
    
    o_values = make_nested_subsets(o, N1_values);
elseif(strcmpi(method_name, 'EFS'))  % binary classification only
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/feature_selection.R "%s" %d %d %d EFS "%s" "%s"', training_file, N, M, isClassification, validation_file, feature_results_file);
    disp(cmd);
    system(cmd);
    o = csvread(feature_results_file)
    
    o_values = make_nested_subsets(o, N1_values);
elseif(strcmpi(method_name, 'mRMRe'))  % binary classification only
    n1str = sprintf('%d,', N1_values);
    n1str = n1str(1:end-1)
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/feature_selection.R "%s" %d %d %d mRMRe "%s" "%s" "%s"', training_file, N, M, isClassification, validation_file, feature_results_file, n1str);
    disp(cmd);
    system(cmd);
    
    o_values = read_subsets(feature_results_file, N1_values);
elseif(strcmpi(method_name, 'EPLOFS'))  % binary classification only
    plnexec = '/home/rohit/Dropbox/PLN2012/PLN2012_NetBeans/PLN2012/dist/Performance/GNU-Linux/pln2012';
    cmd = sprintf('"%s" "%s" "%s" %d %d %d', plnexec, training_file, validation_file, N, M, isClassification);
    disp(cmd);
    system(cmd);
    
    o_values = read_subsets('final_all_subsets.txt', N1_values, true);
else
    fprintf('Unknown method name provided: %s\n', method_name);
    error;
end

etrg_plot = [];
etst_plot = [];
for i = 1:length(N1_values)
    N1 = N1_values(i);
    o1 = o_values{i};
    [error_subset fs_info] = evaluate_subset(training_file, validation_file, N, M, isClassification, o1, testing_file, options);
    etrg_plot = [etrg_plot; error_subset.trg]
    etst_plot = [etst_plot; error_subset.tst]
end
% plot([etrg_plot etst_plot]);
csvwrite([results_base '_EtrgEstVsN1.csv'], [N1_values' etrg_plot etst_plot]);
% pause;

end

function o_values = make_nested_subsets(o, N1_values)

    if(length(o)<max(N1_values))
        orest = setdiff(1:max(N1_values), o);
        o = [o; orest(:)];
    end

    for i = 1:length(N1_values)
        N1 = N1_values(i);
        o_values{i} = o(1:N1);
    end

end

function o_values = read_subsets(fname, N1_values, fileHasAllSubset)

if(nargin<3)
    fileHasAllSubset = false;
end
    fid = fopen(fname, 'r');
    v = fscanf(fid, '%d');
    fclose(fid);
    start = 1;
    o_values = {};
    if(fileHasAllSubset)
        for i = 1:max(N1_values)
            N1 = i;
            x = v(start:start+N1-1);
            if(~isempty(find(N1_values==i)))
                o_values{end+1} = x;
                disp(o_values{end});
            end
            start = start+N1;
        end
    else
        for i = 1:length(N1_values)
            N1 = N1_values(i);
            o_values{i} = v(start:start+N1-1);
            start = start+N1;
            disp(o_values{i});
        end
    end
    
end
