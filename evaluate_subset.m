% % Author: Rohit Rawat <rohit@expanse>
% % Created: 2016-08-31

function [error_subset fs_info] = evaluate_subset(training_file, validation_file, N, M, isClassification, o, testing_file, options)

training_file
pwd1 = pwd;

fs_info.N_best = 0;

error_subset.trg = 0;

fprintf('Feature size: %d\n', length(o));
o = sort(o);
o'
fs_info.N_best = length(o);
fs_info.o = o;

addpath(pwd);
cd(utils.tempdir2);

if(isClassification)

if(options.class_model==1)
    error_subset = mlp_results(training_file, validation_file, N, M, isClassification+1, testing_file, o);
    %[etrg eval etst Nit_best] = train_mlp_matlab(options.basename, N, M, 50, 50, trg_idx, val_idx, tst_idx)
elseif(options.class_model==2)
    error_subset = svm_results(training_file, validation_file, N, M, isClassification+1, testing_file, o)
end

else

if(options.reg_model==1)
    error_subset = mlp_results(training_file, validation_file, N, M, isClassification+1, testing_file, o);
elseif(options.reg_model==2)
    error_subset = svm_results(training_file, validation_file, N, M, isClassification+1, testing_file, o)
elseif(options.reg_model==3)
    error_subset = knn_results(training_file, validation_file, N, M, isClassification+1, testing_file, o);
end

end

fprintf('Switching from %s to %s\n', pwd, pwd1);
cd(pwd1);
o
