% Feature Selection testing program
% ---------------------------------

function main(files_subset)

global matlab_id;
rng('shuffle');
matlab_id = randi(10000);
rng('default');

% initialize
addpath('~/Dropbox/MATLAB/common');

utils.logger('start', num2str(matlab_id));

[exitcode host]=system('hostname');
host = host(1:length(host)-1);

codebase = pwd;

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
lang = 'matlab';
if(isOctave)
  addpath([pwd '/octave']);
  more off;
  lang = 'octave';
end

utils.logger('Running on %s (%s)\nfrom %s\n', host, lang, codebase);

set(0,'DefaultFigureVisible','off');

% temp_folder = fullfile(utils.tempdir2(), 'featuresel');
temp_folder = fullfile('/tmp', 'featuresel');

% system(sprintf('mkdir /tmp/idxs; cp "%s"/*.idx /tmp/idxs/', fullfile(temp_folder, 'data')));
if(nargin==0 || files_subset(1) == 1)
  utils.clean_tempdir('featuresel');
end

mkdir(temp_folder);
mkdir(fullfile(temp_folder, 'data'));
mkdir(fullfile(temp_folder, 'results'));
mkdir(fullfile(temp_folder, 'images'));
% system(sprintf('cp /tmp/idxs/*.idx "%s/"', fullfile(temp_folder, 'data')));

% read file db
addpath('/home/rohit/Dropbox/Research/DataFiles/')
files = load_dataset_info('/home/rohit/Dropbox/Research/DataFiles/files.csv', '/home/rohit/Dropbox/Research/DataFiles/');

% choose files
% files = files([17 18 24 29 22 33 25]);
% files = files([25 17 52 53 56]);
% files = files(57:63);
files = files(53);
if(nargin==1)
    files = files(files_subset);
end

file_names = [];
for i=1:length(files)
  if(i>1)
    file_names=[file_names ','];
  end
  file_names=[file_names files(i).title(1:3)];
  utils.logger('File %d: %s\n', i, files(i).title);
end

% setting

comments = 'FeatureSelection';

archive_folder = '/home/rohit/Dropbox/results_sharing';

NORMAL=0;
NOISE=1;
DEPENDENT=2;
run_mode = NORMAL;

K = 10;
K_do = 10;
trg_ratio = 0.8;
loadIdx = false;

% 1 - MLP
% 2 - SVM
% 3 - KNN (class only)
modelnames = {'MLP', 'SVM', 'KNN'};
options.reg_model = 1;
options.class_model = 2;

[algorithms algo_names algo_names_short] = defineFSAlgorithms();

run_name = sprintf('%s_%s_%s%d_%s_m%d_%s_Reg%s_Cls%s', comments, host, lang, matlab_id, file_names, run_mode, algo_names_short, modelnames{options.reg_model}, modelnames{options.class_model});
disp(run_name)

% backup the code

zipcmd = sprintf('cd %s; zip -r /tmp/%s_code.zip ./ -i \\*.m', codebase, run_name);
disp(zipcmd);
system(zipcmd);

% for each file
for i = 1:length(files)
    
  files(i).isClassification = (files(i).type==2);

  % generate 10-fold datasets
  basename = fullfile(temp_folder, 'data', files(i).title);
  
  input_file = files(i).training_file;
  
    if(isempty(files(i).validation_file) == 0)
        error;
    end
  
  utils.deterministic_srand(0);
  doNormalize = true;
  if(~loadIdx)
    [trg_names tst_names trgval_idx tst_idx grand_imean grand_istd grand_omean grand_ostd] = ...
         file.kfold_splits(input_file, files(i).N, files(i).M, files(i).isClassification, K, basename, doNormalize);
  end
  
  % for each testing fold
  avgPlot_EtrgEstVsN1 = [];
  for k = 1:K_do
    
    % split the training file
    utils.deterministic_srand(1);
    if(~loadIdx)
        [trgfname, valfname, xxx, trg_idx, val_idx, xxx] = ...
            file.split_3parts(trg_names{k}, files(i).N, files(i).M, files(i).isClassification, [trg_ratio 1-trg_ratio 0]);
        trg_idx = trgval_idx{k}(trg_idx);
        val_idx = trgval_idx{k}(val_idx);
        idxmax = max([length(trg_idx), length(val_idx), length(tst_idx{k})]);
        idxMatrix = ones(3,idxmax)*-1;
        idxMatrix(1,1:length(trg_idx)) = trg_idx;
        idxMatrix(2,1:length(val_idx)) = val_idx;
        idxMatrix(3,1:length(tst_idx{k})) = tst_idx{k};
        idxfname = sprintf('%s_%d.idx', basename, k);
        csvwrite(idxfname, idxMatrix);
    else
        idxfname = sprintf('%s_%d.idx', basename, k)
        idxs = csvread(idxfname);
        alldata = dlmread(basename);
        if(doNormalize)
            alldata = bsxfun(@minus, alldata, [m mt]);
            alldata = bsxfun(@rdivide, alldata, [s st]);
        end

        trgidx = idxs(1,:);
        trgidx = trgidx(trgidx>0);
        validx = idxs(2,:);
        validx = validx(validx>0);
        tstidx = idxs(3,:);
        tstidx = tstidx(tstidx>0);
        
        tst_names{i} = [basename '-tst-set-' num2str(i)]; % repeated
        trg_names{i} = [basename '-tra-set-' num2str(i)];
        trgfname = [trg_names{i} '.train'];
        valfname = [trg_names{i} '.validate'];

        dlmwrite(trgfname, alldata(trgidx,:), '\t');
        dlmwrite(valfname, alldata(validx,:), '\t');
        dlmwrite(tst_names{k}, alldata(tstidx,:), '\t');
    end
    tstfname = tst_names{k};

    % Run the algorithms one by one
    
    for algidx = 1:length(algorithms)
        
        results_base = fullfile(temp_folder, 'results', [files(i).title num2str(k) '_' algorithms(algidx).name]);
        images_base = fullfile(temp_folder, 'images', [files(i).title num2str(k) '_' algorithms(algidx).name]);
        ticid = tic;
        evaluateMethod(trgfname, valfname, files(i).N, files(i).M, files(i).isClassification, tstfname, options, results_base, algorithms(algidx).name);
        method_time = toc(ticid);
        csv_name = [results_base '_EtrgEstVsN1.csv'];
        eps_name = [images_base '_EtrgEstVsN1.eps'];
        plotAlgorithm(csv_name, algorithms(algidx).name, eps_name, files(i).isClassification);
        currentPlot = csvread(csv_name);
        if(k==1)
            avgPlot_EtrgEstVsN1{algidx} = currentPlot;
            avg_method_time(algidx) = method_time;
        else
            avgPlot_EtrgEstVsN1{algidx} = avgPlot_EtrgEstVsN1{algidx} + currentPlot;
            avg_method_time(algidx) = avg_method_time(algidx) + method_time;
        end
        
    end
    
  end % end K-folds
  
  for algidx = 1:length(algorithms)
      avgPlot_EtrgEstVsN1{algidx} = avgPlot_EtrgEstVsN1{algidx} / K_do;
      csv_name = fullfile(temp_folder, 'results', [files(i).title '_' algorithms(algidx).name '_avgPlot_EtrgEstVsN1.csv']);
      csvwrite(csv_name, avgPlot_EtrgEstVsN1{algidx});
      algo_names{algidx} = algorithms(algidx).name;
      csv_names{algidx} = csv_name;
      
      avg_method_time(algidx) = avg_method_time(algidx) / K_do;
  end
  eps_name = fullfile(temp_folder, 'images', [files(i).title '_' 'ALL' '_avgPlot_EtrgEstVsN1.eps']);
  plotAlgorithm(csv_names, algo_names, eps_name, files(i).isClassification);
  tictoc_name = fullfile(temp_folder, 'results', [files(i).title '_method_times.csv']);
  csvwrite(tictoc_name, avg_method_time);
  
end

utils.logger('stop');
zipcmd = sprintf('cd %s; zip -r %s/%s.zip ./ -x \\*-set-\\*', temp_folder, archive_folder, run_name);
disp(zipcmd);
system(zipcmd);

zipcmd = sprintf('mv /tmp/%s_code.zip %s/', run_name, archive_folder);
disp(zipcmd);
system(zipcmd);
