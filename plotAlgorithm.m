function plotAlgorithm(csv_fname, algo_name, eps_name, isClassification)

if(iscell(csv_fname))
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/plotEtstVsN1.R "%s" %d', eps_name, isClassification);
    for i=1:length(csv_fname)
        cmd = [cmd sprintf(' "%s" "%s"', csv_fname{i}, algo_name{i})];
    end 
else
    cmd = sprintf('Rscript /home/rohit/Dropbox/PLN2012/FS_tester/R/plotEtstVsN1.R "%s" %d "%s" "%s"', eps_name, isClassification, csv_fname, algo_name);
end

disp(cmd);
system(cmd);
